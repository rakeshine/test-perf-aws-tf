#!/bin/bash
set -euo pipefail

JMETER_HOME=/opt/apache-jmeter-5.6.3
PATH=$JMETER_HOME/bin:$PATH
export PATH

echo "Starting container in JMETER_MODE=${JMETER_MODE}"

if [ "${JMETER_MODE}" == "slave" ]; then

  echo "Starting JMeter slave server..."

  # Start JMeter server process with required flags
  jmeter-server -Dserver.rmi.localport=50000 \
                -Dserver.rmi.ssl.disable=true \
                -Djava.rmi.server.hostname=$(hostname -i)

  echo "JMeter slave running. Waiting for master to finish..."

  # Wait until RMI port is closed (master finishes)
  while ss -lnt | grep -q ':1099'; do
    sleep 5
  done

  echo "Master disconnected. Exiting slave."
  exit 0

elif [ "${JMETER_MODE}" == "master" ]; then

  # Azure: download test plan artifacts
  # Preferred: TEST_PLAN_BLOB_URL points to a single .zip or .jmx (SAS URL)
  # Alternate: TEST_PLANS_PREFIX provides container/prefix for multiple files (requires azcopy if you add it)
  if [ -n "${TEST_PLAN_BLOB_URL:-}" ]; then
    echo "Downloading test plan from Azure Blob: ${TEST_PLAN_BLOB_URL}"
    if echo "${TEST_PLAN_BLOB_URL}" | grep -qiE '\\.zip(\?|$)'; then
      curl -fsSL "${TEST_PLAN_BLOB_URL}" -o test.zip
      unzip -o test.zip -d .
      rm -f test.zip
    else
      curl -fsSL "${TEST_PLAN_BLOB_URL}" -o test.jmx
    fi
  elif [ -n "${TEST_PLANS_PREFIX:-}" ]; then
    echo "TEST_PLANS_PREFIX provided (${TEST_PLANS_PREFIX}) but azcopy is not installed in this image."
    echo "Please provide TEST_PLAN_BLOB_URL (SAS) to a .zip or .jmx instead, or extend image with azcopy."
    exit 1
  else
    echo "No TEST_PLAN_BLOB_URL or TEST_PLANS_PREFIX provided; cannot fetch test plan."
    exit 1
  fi

  if [ -z "${JMETER_SLAVE_HOSTS}" ]; then
    echo "No slaves specified, running locally"
    jmeter -n -t test.jmx -l results.jtl
  else
    echo "Running distributed test with slaves: ${JMETER_SLAVE_HOSTS}"
    
    sed -i '/^remote_hosts=/d' "$JMETER_HOME/bin/jmeter.properties"
    echo "remote_hosts=${JMETER_SLAVE_HOSTS}" >> $JMETER_HOME/bin/jmeter.properties
    
    # TODO Add JIRA integration params to jmeter.proerties and system.properties in bin folder (remove before add)

    jmeter -n -t test.jmx -r -l results.jtl
  fi

  # Azure: upload results via SAS URL if provided
  if [ -n "${RESULTS_BLOB_URL:-}" ]; then
    echo "Uploading test results to Azure Blob"
    curl -fsSL -X PUT --upload-file results.jtl "${RESULTS_BLOB_URL}"
  else
    echo "No RESULTS_BLOB_URL provided; results.jtl remains in the container filesystem."
  fi

  echo "Test completed, exiting"
  exit 0

else
  echo "Error: JMETER_MODE not set or invalid (must be 'master' or 'slave')."
  exit 1
fi