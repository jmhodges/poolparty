#!/bin/sh

# Get the essentials
apt-get -y install build-essential

# Install ruby
echo 'Installing ruby...'
apt-get -y install ruby1.8-dev ruby1.8 ri1.8 rdoc1.8 irb1.8 libreadline-ruby1.8 libruby1.8
ln -sf /usr/bin/ruby1.8 /usr/local/bin/ruby
ln -sf /usr/bin/ri1.8 /usr/local/bin/ri
ln -sf /usr/bin/rdoc1.8 /usr/local/bin/rdoc
ln -sf /usr/bin/irb1.8 /usr/local/bin/irb

# Install rubygems
echo '-- Installing Rubygems'
cd /usr/local/src
wget http://rubyforge.org/frs/download.php/35283/rubygems-1.1.1.tgz
tar -xzf rubygems-1.1.1.tgz
cd rubygems-1.1.1
ruby setup.rb --no-rdoc --no-ri
ln -sf /usr/bin/gem1.8 /usr/bin/gem

# Install gems
gem1.8 update --system
gem1.8 install SQS aws-s3 amazon-ec2 aska rake poolparty --no-rdoc --no-ri --no-test

# Install haproxy
apt-get -y install haproxy
sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/haproxy
sed -i 's/SYSLOGD=\"\"/SYSLOGD=\"-r\"/g' /etc/default/syslogd
echo 'local0.* /var/log/haproxy.log' >> /etc/syslog.conf && killall -9 syslogd && syslogd

# Install heartbeat
apt-get -y install heartbeat-2

# Install monit
apt-get -y install monit
mkdir /etc/monit
sed -i 's/startup=0/startup=1/g' /etc/default/monit
/etc/init.d/monit start

# Install s3fuse
apt-get install -y build-essential libcurl4-openssl-dev libxml2-dev libfuse-dev
cd /usr/local/src && wget http://s3fs.googlecode.com/files/s3fs-r166-source.tar.gz 
tar -zxf s3fs-r166-source.tar.gz
cd s3fs/ && make
mv s3fs /usr/bin
mkdir /data
