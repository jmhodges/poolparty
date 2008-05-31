#!/bin/sh

# Start this instance's master maintain script
:config_master
# Make the ha.d/resource.d
mkdir /etc/ha.d/resource.d/
# Set this hostname as appropriate in the cloud
:set_hostname
# Configure heartbeat
mkdir /etc/ha.d/resource.d/
# Start heartbeat
/etc/init.d/heartbeat start
# Start s3fs
:start_s3fs
# Configure monit
mkdir /etc/monit.d
