#!/bin/sh

# Move the hosts file
:move_hostfile
# Move the authkeys
:configure_authkeys
# Move the config file
:move_config_file
# Reconfigure master if master?
:config_master
# Configure haproxy
:configure_haproxy
# Set this hostname as appropriate in the cloud
:set_hostname
# Configure heartbeat
:configure_resouce_d
# Start heartbeat
:configure_heartbeat
# Start s3fs
:mount_s3_drive
# Configure monit
:configure_monit
# Update the plugins
:update_plugins