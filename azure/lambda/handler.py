import os
import time
import json
import socket
import datetime
from typing import Dict, List, Any

from azure.identity import DefaultAzureCredential
from azure.storage.blob import BlobServiceClient, generate_blob_sas, BlobSasPermissions
from azure.mgmt.containerinstance import ContainerInstanceManagementClient
from azure.mgmt.containerinstance.models import (
    ContainerGroup,
    Container,
    ContainerPort,
    OperatingSystemTypes,
    ResourceRequests,
    ResourceRequirements,
    EnvironmentVariable,
    ImageRegistryCredential,
)

# ------------------------------
# Config and constants
# ------------------------------
SLAVE_READY_TIMEOUT = 300  # 5 minutes
SLAVE_CHECK_INTERVAL = 5
JMETER_RMI_PORT = 1099
MASTER_DEFAULT_PORTS = [1099, 50000]

# Best practice for artifacts:
# - Blob container "test-plans"; per-run prefix test-plans/<run_id>/
# - File share "jmeter-results" for results (mounted in container if needed)


def _now_run_id() -> str:
    return datetime.datetime.utcnow().strftime("%Y%m%dT%H%M%SZ")


def get_env(name: str, default: str = "") -> str:
    v = os.getenv(name, default)
    if v is None:
        return default
    return v


def build_blob_clients() -> BlobServiceClient:
    # Prefer connection string for simplicity. Fall back to account URL + DefaultAzureCredential
    conn = os.getenv("AZURE_STORAGE_CONNECTION_STRING")
    if conn:
        return BlobServiceClient.from_connection_string(conn)
    account_url = os.getenv("AZURE_STORAGE_ACCOUNT_URL")  # e.g. https://<account>.blob.core.windows.net
    if not account_url:
        raise ValueError("AZURE_STORAGE_CONNECTION_STRING or AZURE_STORAGE_ACCOUNT_URL must be set")
    cred = DefaultAzureCredential()
    return BlobServiceClient(account_url=account_url, credential=cred)


def ensure_container(bs: BlobServiceClient, container: str):
    try:
        bs.create_container(container)
    except Exception:
        pass  # already exists


def upload_test_artifacts(bs: BlobServiceClient, container: str, run_prefix: str, local_dir: str) -> str:
    # Upload .jmx/.csv/.properties files to test-plans/<run_prefix>/
    ensure_container(bs, container)
    c = bs.get_container_client(container)
    for fname in os.listdir(local_dir):
        if fname.lower().endswith((".jmx", ".csv", ".properties")):
            blob_name = f"{run_prefix}/{fname}"
            with open(os.path.join(local_dir, fname), "rb") as f:
                c.upload_blob(name=blob_name, data=f, overwrite=True)
    return f"{container}/{run_prefix}"


def generate_sas_for_prefix(account_name: str, container: str, blob_name: str, expiry_minutes: int = 60) -> str:
    # Generate SAS for a single blob (the entry .jmx); clients can fetch companion files by name if they embed them.
    # For broader access, generate SAS per needed file.
    from datetime import datetime, timedelta

    key = os.getenv("AZURE_STORAGE_ACCOUNT_KEY")
    if not key:
        # If using AAD auth, containers should access via managed identity; skip SAS
        return ""
    sas = generate_blob_sas(
        account_name=account_name,
        container_name=container,
        blob_name=blob_name,
        account_key=key,
        permission=BlobSasPermissions(read=True, list=True),
        expiry=datetime.utcnow() + timedelta(minutes=expiry_minutes),
    )
    return sas


def build_aci_client() -> ContainerInstanceManagementClient:
    cred = DefaultAzureCredential()
    sub_id = os.environ["AZ_SUBSCRIPTION_ID"]
    return ContainerInstanceManagementClient(credential=cred, subscription_id=sub_id)


def create_aci(
    aci: ContainerInstanceManagementClient,
    resource_group: str,
    name: str,
    location: str,
    subnet_id: str,
    image: str,
    cpu: float,
    memory: float,
    ports: List[int],
    envs: Dict[str, str],
    registry: Dict[str, str] | None = None,
) -> str:
    container = Container(
        name=name,
        image=image,
        resources=ResourceRequirements(
            requests=ResourceRequests(cpu=cpu, memory_in_gb=memory)
        ),
        ports=[ContainerPort(port=p) for p in ports],
        environment_variables=[EnvironmentVariable(name=k, value=v) for k, v in envs.items()],
    )

    ip_address = None  # private only if subnet provided
    group = ContainerGroup(
        location=location,
        containers=[container],
        os_type=OperatingSystemTypes.linux,
        subnet_ids=[{"id": subnet_id}] if subnet_id else None,
        restart_policy="OnFailure",
        image_registry_credentials=(
            [ImageRegistryCredential(server=registry.get("server"), username=registry.get("username"), password=registry.get("password"))]
            if registry and all(registry.get(k) for k in ("server", "username", "password"))
            else None
        ),
        ip_address=ip_address,
    )

    aci.container_groups.begin_create_or_update(resource_group, name, group).result()
    # Retrieve IP (private IP assigned in subnet)
    cg = aci.container_groups.get(resource_group, name)
    # For private groups, network profile assigns IP inside subnet; Azure SDK returns ip_address None. We'll rely on DNS/hostname inside VNet
    # If public IP needed (not recommended here), you would set ip_address with type Public and Ports.
    return cg.id


def get_container_private_ip(aci: ContainerInstanceManagementClient, resource_group: str, name: str) -> str:
    cg = aci.container_groups.get(resource_group, name)
    # Private IP is currently not surfaced directly for VNet-injected ACI; containers can resolve peers by DNS within subnet.
    # If needed, query instance view logs to derive IP, or switch to Public IP for orchestration-only.
    # As a pragmatic approach, return empty and expect an external discovery or provide MASTER_HOST via env.
    return ""


def wait_for_slaves_ready(ips: List[str]) -> List[str]:
    ready = set()
    start = time.time()
    while time.time() - start < SLAVE_READY_TIMEOUT:
        for ip in ips:
            if ip in ready or not ip:
                continue
            try:
                s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
                s.settimeout(2)
                res = s.connect_ex((ip, JMETER_RMI_PORT))
                s.close()
                if res == 0:
                    ready.add(ip)
            except Exception:
                pass
        if len(ready) == len([i for i in ips if i]):
            break
        time.sleep(SLAVE_CHECK_INTERVAL)
    return list(ready)


def azure_handler(event: Dict[str, Any]) -> Dict[str, Any]:
    # Inputs via event or env
    location = get_env("AZ_LOCATION", event.get("location", ""))
    resource_group = get_env("AZ_RESOURCE_GROUP", event.get("resource_group", ""))
    subnet_id = get_env("ACI_SUBNET_ID", event.get("subnet_id", ""))

    master_image = get_env("MASTER_IMAGE", event.get("master_image", ""))
    master_cpu = float(get_env("MASTER_CPU", str(event.get("master_cpu", 1))))
    master_memory = float(get_env("MASTER_MEMORY", str(event.get("master_memory", 1.5))))
    master_ports = event.get("master_ports", MASTER_DEFAULT_PORTS)

    slave_image = get_env("SLAVE_IMAGE", event.get("slave_image", ""))
    slave_cpu = float(get_env("SLAVE_CPU", str(event.get("slave_cpu", 0.5))))
    slave_memory = float(get_env("SLAVE_MEMORY", str(event.get("slave_memory", 1.0))))
    slave_count = int(get_env("SLAVE_COUNT", str(event.get("slave_count", 2))))

    storage_account = os.getenv("AZURE_STORAGE_ACCOUNT_NAME")  # for SAS generation
    test_container = get_env("TEST_PLANS_CONTAINER", "test-plans")

    # Prepare test artifacts: assume a prior step has placed artifacts locally at /tmp/test_package
    # Or event specifies container/prefix already. Best practice: per-run prefix
    run_id = event.get("run_id", _now_run_id())
    artifacts_dir = event.get("artifacts_dir", "/tmp/test_package")
    entry_jmx = event.get("entry_jmx", "test.jmx")

    bs = build_blob_clients()
    prefix = upload_test_artifacts(bs, test_container, run_id, artifacts_dir)

    # SAS for the main JMX (optional, if containers use managed identity to read)
    sas = generate_sas_for_prefix(storage_account, test_container, f"{prefix}/{entry_jmx}")
    test_plan_url = (
        f"https://{storage_account}.blob.core.windows.net/{test_container}/{prefix}/{entry_jmx}{('?'+sas) if sas else ''}"
        if storage_account else ""
    )

    aci = build_aci_client()

    # Start slaves
    slave_names = []
    slave_ips: List[str] = []
    for idx in range(slave_count):
        name = f"jmeter-slave-{run_id}-{idx}"
        envs = {
            "JMETER_MODE": "slave",
            # optionally provide artifacts prefix if slaves need data files
            "TEST_PLANS_PREFIX": f"{test_container}/{prefix}",
        }
        create_aci(
            aci,
            resource_group,
            name,
            location,
            subnet_id,
            slave_image,
            slave_cpu,
            slave_memory,
            ports=[JMETER_RMI_PORT],
            envs=envs,
        )
        slave_names.append(name)
        ip = get_container_private_ip(aci, resource_group, name)
        slave_ips.append(ip)

    # Wait for slaves (if IPs are available). If not, master_host will be passed explicitly later.
    ready = wait_for_slaves_ready(slave_ips) if any(slave_ips) else []

    # Start master
    master_name = f"jmeter-master-{run_id}"
    envs_master = {
        "JMETER_MODE": "master",
        # If we discovered slave IPs, provide them; otherwise expect JMETER_MASTER_HOST to be set out-of-band
        "JMETER_SLAVE_HOSTS": ",".join([f"{ip}:{JMETER_RMI_PORT}" for ip in ready]) if ready else "",
        "TEST_PLAN_BLOB_URL": test_plan_url,
        "TEST_PLANS_PREFIX": f"{test_container}/{prefix}",
    }
    create_aci(
        aci,
        resource_group,
        master_name,
        location,
        subnet_id,
        master_image,
        master_cpu,
        master_memory,
        ports=MASTER_DEFAULT_PORTS,
        envs=envs_master,
    )

    return {
        "statusCode": 200,
        "body": json.dumps(
            {
                "run_id": run_id,
                "master_name": master_name,
                "slave_names": slave_names,
                "ready_slave_ips": ready,
                "test_plans_prefix": f"{test_container}/{prefix}",
                "entry_jmx": entry_jmx,
            }
        ),
    }


def handler(event: Dict[str, Any], context: Any | None = None) -> Dict[str, Any]:
    # Entry point compatible with Azure Functions or other runner
    try:
        return azure_handler(event)
    except Exception as e:
        import traceback
        return {
            "statusCode": 500,
            "body": json.dumps({
                "error": str(e),
                "stack_trace": traceback.format_exc(),
            }),
        }