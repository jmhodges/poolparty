#!/bin/sh

:config_master
# Make the ha.d/resource.d
mkdir /etc/ha.d/resource.d/
:set_hostname
# Configure heartbeat
:configure_heartbeat 
mkdir /etc/ha.d/resource.d/
# Start heartbeat
/etc/init.d/heartbeat start
# Start s3fs
:start_s3fs
# Configure monit
mkdir /etc/monit.d
