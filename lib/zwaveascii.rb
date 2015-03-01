require 'rubygems'
require 'serialport'

module ZWave
  class ASCII
    VERSION = "0.0.6"
    TIMEOUT = 2

    def initialize(port, speed = 9600, debug = false)
      @debug = debug
      @port = SerialPort.new(port, speed, 8, 1, SerialPort::NONE)
      @port.read_timeout = 25
      throw "Failed to open port #{device} for ZWave ASCII interface" unless @port
      @event_queue = Array.new
    end
    
    def protocol_debug=(value)
      @protocol_debug = value
    end

    def debug=(value)
      @debug = value
    end
    
    def debug_msg(text)
      puts text if @debug
    end

    def switch(address)
    	Switch.new self, address
    end
    
    def dimmer(address)
    	Dimmer.new self, address
    end

    def fetch_events
    	return nil if @port.eof?
    	while(!@port.eof?) do
	  @event_queue.push parse_event(@port.readline)
	end
	events = @event_queue
	@event_queue = Array.new
	events
    end

    def parse_event(data)
    	matchdata = /<N(\d+):(\d+),(.*)/.match(data)
	# security responses are a bit different
    	matchdata = /<n(\d+):\d+,(\d+),(.*)/.match(data) if !matchdata
	
	node = matchdata[1].to_i
	cmdclass = matchdata[2].to_i
	args = matchdata[3].split(",")
	case(cmdclass)
	  when 0x20
	    return BasicEvent.new node, cmdclass, args[0], args[1]
	  when 0x2B
	    return SceneActivationEvent.new node, cmdclass, args[1]
	  when 0x71
	    return NotificationEvent.new node, cmdclass, args[1].to_i, (args[7] ? args[7].to_i : nil)
	  else
	    return Event.new node, cmdclass
	end
    end

    def send_cmd(cmd, expected_response_frames)
    	debug_msg "Writing: #{cmd}"
    	@port.write "#{cmd}\n"
	return_val = []
	expected_response_frames.each do |expected_type|
	  timed_out = true
	  for timeout_done in (0..TIMEOUT).step(0.1) do
	    sleep 0.1
	    if(!@port.eof?) then
	      timed_out = false
	      break
	    end
	    debug_msg "Retrying read, #{TIMEOUT - timeout_done} seconds left"
	  end
	  raise IOError, "Timeout waiting for response from interface" if timed_out
	  response = @port.readline
	  type = response[1].chr
	  code = response[2..-1].to_i
	  debug_msg "Got response type '#{type}'"
	  raise(IOError, "Expected #{expected_type} frame but got #{type}") unless type == expected_type
	  case type
	    when "E"
	      raise(IOError, "Received abnormal E code #{code}") unless code == 0
	    when "X"
	      raise(IOError, "Received abnormal X code #{code}") unless code == 0
	    when "N"
	      return_val.push response[1..-1]
	  end
	end
	return_val
    end

    def switch_on(address)
      send_cmd ">N#{address}ON", ["E", "X"]
    end
    
    def switch_off(address)
      send_cmd ">N#{address}OFF", ["E", "X"]
    end
    
    def dim(address, level)
      level = 99 if level > 99;	# there is no 100, it's 0-99
      level = 0 if level < 0;
      send_cmd ">N#{address}L#{level}", ["E", "X"]
    end

    def get_level(address)
      response = send_cmd(">?N#{address}", ["E", "X", "N"])
      response[0][6..-1].to_i
    end
  end

  class Node
    def initialize(controller, address)
      @controller = controller
      @address = address
    end
  end
  
  class Switch < Node
    def initialize(controller, address)
      super controller, address
    end
    
    def on=(state)
      if(state) then
        @controller.switch_on @address
      else
        @controller.switch_off @address
      end
    end

    def on?
      @controller.get_level(@address) != 0 ? true : false
    end
  end

  class Dimmer < Switch
    def initialize(controller, address)
      super controller, address
    end

    def level=(level)
    	@controller.dim @address, level
    end

    def level
      # map 0-99 to 0-100 so we output percentage
      @controller.get_level(@address) * 100 / 99;
    end
  end

  class Event
    attr_reader :node, :cmdclass
    
    def initialize(node, cmdclass)
      @node = node
      @cmdclass = cmdclass
    end
  end
  
  class BasicEvent < Event
    attr_reader :type, :value 
    
    def initialize(node, cmdclass, type, value)
      @type = type
      @value = value
      super node, cmdclass
    end
  end

  class SceneActivationEvent < Event
    attr_reader :scene

    def initialize(node, cmdclass, scene)
      @scene = scene.to_i
      super node, cmdclass
    end
  end

  class NotificationEvent < Event
    attr_reader :type, :code_used
    
    def initialize(node, cmdclass, type, code_used)
      case type
        when 0x12
	  @type = :locked
	when 0x13
	  @type = :unlocked
	when 0x15
	  @type = :manually_locked
	when 0x16
	  @type = :manually_unlocked
	else
	  @type = type
      end
      @code_used = code_used
      super node, cmdclass
    end
  end
end
