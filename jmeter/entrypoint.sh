#!/bin/bash
set -e
 
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
 
  echo "Downloading test plan from S3: ${TEST_PLAN_S3}"
  aws s3 sync "${TEST_PLAN_S3}" ./
 
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
 
  if [ -n "${RESULT_S3}" ]; then
    echo "Uploading test results to ${RESULT_S3}"
    aws s3 cp results.jtl "${RESULT_S3}"
 
    # TODO result JTL to be copied to test-surge-perf-db bucket with timestamp within proper folder
  fi
 
  echo "Test completed, exiting"
  exit 0
 
else
  echo "Error: JMETER_MODE not set or invalid (must be 'master' or 'slave')."
  exit 1
fi