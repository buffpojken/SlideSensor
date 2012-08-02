require 'socket'                                         
require 'json'
sock = UDPSocket.new
data = {:key => "temperature", :value => "laser"}.to_json
sock.send(data, 0, '0.0.0.0', 8080)
sock.close