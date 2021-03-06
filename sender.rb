require 'socket'                                         
require 'json'

payload = {"type"=>"state", "data"=>{"node"=>{"started"=>"2012-08-02 20:01:53", "pid"=>22467, 
  "child"=>22468, "device"=>{"error"=>0, "majorVersion"=>2, "minorVersion"=>9, "buildVersion"=>930, 
    "name"=>"BX PLC Server\u0000\u0000"}, "state"=>{"error"=>0, "adsState"=>5, "deviceState"=>0}}, 
   "Interface"=>{
     "ibPump"=>false, "ibRelease"=>false, "ibForceRed"=>false, "ibForceYellow"=>false, "
     ibForceGreen"=>false, "obPumping"=>false, "obReady"=>true, "obRed"=>false, 
     "obYellow"=>false, "obGreen"=>false, "obFalseStart"=>false, "onTime1"=>0, 
     "onTime2"=>0, "onTime3"=>0, "onTimeTotal"=>0, "onState"=>0, 'temperature' => 16.4}}, "from"=>"beckhoff"}

sock = UDPSocket.new

payload['data']['Interface']['onState'] = 3
sock.send(payload.to_json, 0, '0.0.0.0', 8282)
sleep 5
payload['data']['Interface']['obYellow'] = true
payload['data']['Interface']['onState'] = 3
sock.send(payload.to_json, 0, '0.0.0.0', 8282)
sleep 5
payload['data']['Interface']['obYellow'] = true
payload['data']['Interface']['onTime1'] = Time.now.to_i
payload['data']['Interface']['onTime2'] = Time.now.to_i
payload['data']['Interface']['onTime3'] = Time.now.to_i
payload['data']['Interface']['onTimeTotal'] = Time.now.to_i
payload['data']['Interface']['onState'] = 4
sock.send(payload.to_json, 0, '0.0.0.0', 8282)   
sleep 5
payload['data']['Interface']['onTimeTotal'] = Time.now.to_i
payload['data']['Interface']['obYellow'] = false
payload['data']['Interface']['onState'] = 4
sock.send(payload.to_json, 0, '0.0.0.0', 8282)

sock.close          

# require 'socket'
# require 'json'               
# 
# sock = UDPSocket.new                  
# sock.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, 1)
# payload = {
#   "to"    => "bunny", 
#   "cmd"   => "play",                                     
#   "from"  => "debugger",
#   "value" => "/home/buffpojken/joker.mp3"
# }
# sock.send(payload.to_json+"\n", 0, '192.168.3.15', 8282)
# sock.close


# 
# sock = UDPSocket.new                  
# sock.setsockopt(Socket::SOL_SOCKET, Socket::SO_BROADCAST, 1)
# payload = {
#   "to"    => "bunny", 
#   "cmd"   => "play", 
#   "from"  => "slider",
#   "value" => "http://compuball.com/av/audio1/HellMarch.mp3"
# }
# sock.send(payload.to_json+"\n", 0, 'banan.vassaro.net', 8282)
# sock.close  