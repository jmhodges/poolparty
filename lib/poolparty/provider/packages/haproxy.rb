# Install haproxy
package :haproxy, :provides => :proxy do
  description 'Haproxy proxy'
  apt %w( haproxy )
end