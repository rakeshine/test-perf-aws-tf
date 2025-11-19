# AzureRM backend configuration (fill in and use during `terraform init`)
# Usage:
# terraform -chdir=envs/prod init -backend-config=../../backend.hcl

resource_group_name  = "tfstate-rg"
storage_account_name = "tfstateprodjmeterinfra"  # must be globally unique, 3-24 lowercase alphanum
container_name       = "tfstate"
key                  = "jmeter-infra.prod.tfstate"
