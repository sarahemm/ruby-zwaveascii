require 'rubygems'
require 'serialport'

module ZWave
  class ASCII
    VERSION = "0.0.2"

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
	node = matchdata[1].to_i
	cmdclass = matchdata[2].to_i
	args = matchdata[3].split(",")
	case(cmdclass)
	  when 0x20
	    return BasicEvent.new cmdclass, args[0], args[1]
	  when 0x2B
	    return SceneActivationEvent.new cmdclass, args[1]
	  else
	    return Event.new cmdclass
	end
    end

    def send_cmd(cmd, expected_response_lines)
    	debug_msg "Writing: #{cmd}"
    	@port.write "#{cmd}\n"
	expected_response_lines.times do
          p @port.readline
	end
    end

    def switch_on(address)
      send_cmd ">N#{address}ON", 2
    end
    
    def switch_off(address)
      send_cmd ">N#{address}OFF", 2
    end
    
    def dim(address, level)
      send_cmd ">N#{address}L#{level}", 2
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
  end

  class Dimmer < Switch
    def initialize(controller, address)
      super controller, address
    end

    def level=(level)
    	@controller.dim @address, level
    end
  end

  class Event
    attr_reader :cmdclass
    
    def initialize(cmdclass)
      @cmdclass = cmdclass
    end
  end
  
  class BasicEvent < Event
    attr_reader :type, :value 
    
    def initialize(cmdclass, type, value)
      @type = type
      @value = value
      super cmdclass
    end
  end

  class SceneActivationEvent < Event
    attr_reader :scene

    def initialize(cmdclass, scene)
      @scene = scene
      super cmdclass
    end
  end
end
