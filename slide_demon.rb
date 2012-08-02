require 'eventmachine'
require 'mysqlplus'
require 'em-mysqlplus'
require 'json'

module UDPSensorParser  
   def receive_data data                                                                
     data = JSON.parse(data)
	   q = $db.query("insert into data_points(data_key, data_value, created_at, updated_at) values('"+data["key"]+"', '"+data["value"]+"', NOW(), NOW());")
	   q.callback do |res|
       puts res.inspect
     end               
     q.errback do |res|
       puts res.inspect
     end
     
   end  
end  


EventMachine::run {  
  $db = EventMachine::MySQL.new(:host => "localhost", :username => "root", :database => "kanan_dev")    
  EventMachine::open_datagram_socket "0.0.0.0", 8080, UDPSensorParser  
}