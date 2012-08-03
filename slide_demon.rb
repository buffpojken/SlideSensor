require 'eventmachine'
require 'mysqlplus'
require 'em-mysqlplus'
require 'evma_httpserver'
require 'json'  
require 'cgi'

class APIServer < EM::Connection
  include EM::HttpServer

  def post_init
    super
    no_environment_strings
  end        

  def process_http_request
    params = CGI::parse((@http_query_string || ""))      
    
    if @http_path_info == "/pump"
      $pump.toggle
    end
    if @http_path_info == "/light"
      $light.force(params["light"][0])
    end
    response = EM::DelegatedHttpResponse.new(self)
    response.status = 200
    response.content_type 'text/javascript'     
    status = {:pump => $pump.state, :red => $light.red, :yellow => $light.yellow, :green => $light.green}
    response.content = "#{params["callback"][0]}(#{status.to_json})"
    response.send_response      
  end
end

class Pump 
  attr_accessor :state
  def set(data)
    self.state = data['obPumping'] 
  end  
  
  def toggle
    payload = {
      "to"    => "beckhoff", 
      "cmd"   => "set", 
      "tag"   => "ibPump",
      "from"  => "slider",
      "value" => !self.state
    }          
    self.state = !self.state
    $oc.send(payload.to_json+"\n", 0)
  end
end

class Trafficlight
  attr_accessor :red, :green, :yellow, :captured

  def initialize
    self.captured = false
  end    
  
  def force(light)   
    payload = {
      "to"    => "beckhoff", 
      "cmd"   => "set", 
      "from"  => "slider",
    }        
    case light
      when "green"              
        payload['tag'] = "ibForceGreen"    
        if self.green
          payload['value'] = true            
          self.green = true
        else          
          payload['value'] = false            
          self.green = false
        end
      when "yellow"          
        payload['tag'] = "ibForceYellow"
        if self.yellow
          payload['value'] = true
          self.yellow = true
        else
          payload['value'] = false
          self.yellow = false          
        end
       when "red"            
        payload['tag'] = "ibForceRed"
        if self.red
          payload['value'] = true
          self.red = true        
        else
          payload['value'] = false
          self.red = false
        end
      end
    $oc.send(payload.to_json+"\n", 0)    
  end

  def set(data)
    self.red_light = data['obRed']
    self.green_light = data['obGreen']
    self.yellow_light = data['obYellow']
  end           

  private

  def red_light=(flag)
    self.red = true if flag
  end

  def yellow_light=(flag)
    self.yellow = true if flag
  end

  def green_light=(flag)
    self.green = true if flag
  end         

end

class Ride
  attr_accessor :points, :start, :stop, :state

  def initialize()
    self.start, self.stop, self.points = false, false, []
  end

  def <<(data)
    self.start = data["onTime1"]      
    self.points[0] = data['onTime2']
    self.points[1] = data['onTime3']
    self.stop  = data["onTimeTotal"]
    self.state = data['onState']
    if self.state = 4
      self.save
    end
  end                                 

  def save
    puts "insert into photos(temperature, ride_time, ride_no, timestamp_1, timestamp_2, timestamp_3, created_at, updated_at) select #{$temperature}, #{self.stop}, count(*)+1, #{self.start}, #{self.points[0]}, #{self.points[1]}, NOW(), NOW() from photos"
    q = $db.query("insert into photos(temperature, ride_time, ride_no, timestamp_1, timestamp_2, timestamp_3, created_at, updated_at) select #{$temperature}, #{self.stop}, count(*)+1, #{self.start}, #{self.points[0]}, #{self.points[1]}, NOW(), NOW() from photos")    
    q.callback do |res|
      $ride = Ride.new
      puts "Saved"
    end
    q.errback do |res|
      puts res.inspect      
    end
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

class SensorParser < EventMachine::Connection
  def receive_data(data) 
    data = JSON.parse(data)
    puts data.inspect
    unless data["type"] == "state"
      return
    end                    
    return if !data['data'] || data['data'].empty?

    if data['data']['Interface']
      $light.set(data['data']['Interface'])           
      $pump.set(data['data']['Interface'])
      manage_temperature(data['data']['Interface']['temperature'])
      $ride << data['data']["Interface"]                   
    end

    puts $light.inspect
    puts $ride.inspect       
    puts $pump.inspect
  end   

  private 

  def manage_temperature(temp)      
    return if temp.nil? || temp.empty?
    unless $temperature == temp  
      q = $db.query("insert into data_points(data_key, data_value, created_at, updated_at) values('temperature', '"+temp.to_s+"', NOW(), NOW())")
      q.callback do |res|
        $temperature = temp
      end                                                      
      q.errback do |res|                                                 
        puts res
      end
    end    
  end 

end  


cl = UDPSocket.new
cl.setsockopt(Socket::SOL_SOCKET,Socket::SO_REUSEADDR,1)
cl.bind('0.0.0.0', 8282)
                           
$oc = UDPSocket.new                  
$oc.connect('0.0.0.0', 8282)

EventMachine::run {         
  $db = EventMachine::MySQL.new(:host => "localhost", :username => "root", :database => "kanan_dev")  
  $ride           = Ride.new        
  $light          = Trafficlight.new
  $temperature    = 0                
  $pump           = Pump.new                

  read = EventMachine.attach(cl, SensorParser)  
  EM.start_server '0.0.0.0', 4568, APIServer
}