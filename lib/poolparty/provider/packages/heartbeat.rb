package :heartbeat, :provides => :failover do
  description "Heartbeat Linux HA project"
  apt %w( heartbeat-2 )
end
