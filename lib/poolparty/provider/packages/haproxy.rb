# Install haproxy

def post_install_string
  %w(
    "echo 'Configuring haproxy logging'"
    "sed -i 's/ENABLED=0/ENABLED=1/g' /etc/default/haproxy"
    "sed -i 's/SYSLOGD=\"\"/SYSLOGD=\"-r\"/g' /etc/default/syslogd"
    "echo 'local0.* /var/log/haproxy.log' >> /etc/syslog.conf && /etc/init.d/sysklogd restart"
    "/etc/init.d/haproxy restart"
  )
end

package :haproxy, :provides => :proxy do
  description 'Haproxy proxy'
  # version '1.2.18'
  # source "http://haproxy.1wt.eu/download/1.2/src/haproxy-#{version}.tar.gz"
  apt %w( haproxy )
  
  post :install, post_install_string
end