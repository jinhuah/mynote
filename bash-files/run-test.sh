#!/bin/bash -e

if [ $# -ne 1 ]; then
  echo "Usage $0 <vagrant directory>"
  exit 1
fi

SCRIPT_DIR=$(cd $(dirname $0) && pwd)
VAGRANT_DIR=$(cd $1 && pwd)

mkdir -p ${VAGRANT_DIR}/staging
cd $VAGRANT_DIR/staging

# copy/ create the most recent puppet bootstap files
$SCRIPT_DIR/../../puppet/bootstrap/create_bootstrap.sh
cp $SCRIPT_DIR/../../puppet/bootstrap/install_bootstrap.sh .

# destroy and old VM (if it exists)
vagrant destroy -f

# start new view including Puppet and Insight installation
vagrant up

# load trivial data into pipeline
vagrant ssh -c "cd /home/insight/app/insight-entellus && bin/pipeline_apply_data /mnt/pipeline data/default-set"

# ensure pipeline has a chance to see the data
sleep 30

# wait for pipeline to finish running - give it up to 15 minutes
timeout=$(date "+%s" -d "now + 15 minutes")
while [ $(vagrant ssh -c "pipeline state") == "running" ]
do
    if [ $(date +"%s") -gt $timeout ]; then
        echo "pipeline timed out"
        false
    fi

    echo "running..."
    sleep 60
done

if [ $(vagrant ssh -c "pipeline state") != "idle" ]; then

    echo "pipeline failed to complete successfully"
    false
fi

# Bundle up the SQL tests
tar -czvf tests.tar.gz ../../tests/smoke-test

# Copy onto the VM
${SCRIPT_DIR}/util/vagrant-scp.sh tests.tar.gz tests.tar.gz

# extract
vagrant ssh -c "tar -xzvf tests.tar.gz"

# And run
vagrant ssh -c "cd tests/smoke-test && ./test-all.sh"
