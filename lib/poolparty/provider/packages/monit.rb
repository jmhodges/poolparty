package :monit do
  description "Monit monitoring service"
  apt %w( monit )
  
  post :apt, "sudo mkdir /etc/monit", "sed -i 's/startup=0/startup=1/g' /etc/default/monit"
end
