require 'rubygems'
require 'serialport'

module ZWave
  class ASCII
    VERSION = "0.0.1"

    def initialize(port, speed = 9600, debug = false)
      @debug = debug
      @port = SerialPort.new(port, speed, 8, 1, SerialPort::NONE)
      @port.read_timeout = 1000
      throw "Failed to open port #{device} for ZWave ASCII interface" unless @port
      @receive_buffer = Array.new
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

    def poll
    	p @port.gets
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
end
