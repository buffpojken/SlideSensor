require 'eventmachine'
require 'mysqlplus'
require 'em-mysqlplus'
require 'json'

class Ride
  attr_accessor :points, :start, :stop, :state

  def initialize()
    self.start, self.stop, self.points = false, false, []
  end

  def <<(data)
    # 
  end                                 

  def save
    # Write to db here...
  end
end                                   


# From addr: 'AF_INET,42355,212.214.78.157,212.214.78.157', 
# msg: '{"type":"state","data":{"node":{"started":"2012-08-02 19:09:53","pid":21775,"child":21776,"device":
# {"error":0,"majorVersion":2,"minorVersion":9,"buildVersion":930,"name":"BX PLC Server\u0000\u0000"},"state":
# {"error":0,"adsState":5,"deviceState":0}},
# "Interface":{"ibPump":false,"ibRelease":false,"ibForceRed":false,
#             "ibForceYellow":false,"ibForceGreen":false,"obPumping":false,
#             "obReady":true,"obRed":false,"obYellow":false,"obGreen":false,
#             "obFalseStart":false,"onTime1":0,"onTime2":0,
#             "onTime3":0,"onTimeTotal":0,"onState":0}},
# "from":"beckhoff"}         

require 'eventmachine'

module SensorParser  
  def receive_data(data) 
    data = JSON.parse(data)
    puts data.inspect
    
  end  
end  


cl = UDPSocket.new
cl.setsockopt(Socket::SOL_SOCKET,Socket::SO_REUSEADDR,1)
cl.bind('0.0.0.0', 8282)

EventMachine::run {  
	$ride = Ride.new
	read = EventMachine.attach(cl, SensorParser)
}