require 'rubygems'
require 'serialport'
require 'zwaveascii/events.rb'
require 'zwaveascii/devices.rb'

class Array
  # same as .delete but only delete the first occurance
  def delete_first(delete_val)
    self.each_index do |idx|
      next if self[idx] != delete_val
      self.delete_at idx
      return true
    end
    return false
  end
end

module ZWave
  class ASCII
    VERSION = "0.1.0"
    TIMEOUT = 3

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
    
    def door_lock(address)
    	DoorLock.new self, address
    end

    # tell the controller to reset its internal state and flush our buffer
    def abort
      while(!@port.eof?) do
        @port.read
      end
      send_cmd "AB", ["E"]
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
    	debug_msg "Read Event: #{data.chomp}"
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

    def send_cmd(cmd, expected_response_frames, node = nil)
    	debug_msg "Writing: #{cmd}"
    	@port.write "#{cmd}\n"
	return_val = []
	while true do
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
	  debug_msg "Got response '#{response.strip}'"
          debug_msg "Received unexpected frame #{type} while waiting for #{expected_response_frames}, ignoring." if !expected_response_frames.include? type
	  case type
	    when "E"
	      raise(IOError, "Received abnormal E code #{code}") unless code == 0
	    when "X"
	      raise(IOError, "Received abnormal X code #{code}") unless code == 0
	    when "N", "n"
	      node_addr = /[Nn](\d+)/.match(response)[1]
              if(node && node_addr.to_i != node.to_i) then
	        puts "Ignoring node response from node #{node_addr}, expecting resonse for node #{node}."
		next
	      end
	      return_val.push response[1..-1]
	  end
          expected_response_frames.delete_first type
          break if expected_response_frames.length == 0
	  # the timeout logic in the read section above handles breaking out of
	  # this loop if we never get something we're waiting for
	  debug_msg "Still waiting for frames #{expected_response_frames}..."
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
      response = send_cmd(">?N#{address}", ["E", "X", "N"], address)
      response[0][6..-1].to_i
    end
  end
end
