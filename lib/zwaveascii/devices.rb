module ZWave
  class Node
    def initialize(controller, address)
      @controller = controller
      @address = address
    end
  end
  
  class BatteryNode < Node
    def initialize(controller, address)
      super controller, address
    end
    
    def battery_level
      response = @controller.send_cmd ">N#{@address}SS128,2", ["E", "N", "X", "N", "n"] 
      response[2].split(",")[3].to_i
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

  class DoorLock < BatteryNode
    def initialize(controller, address)
      super controller, address
    end

    def locked?
      response = @controller.send_cmd ">N#{@address}SS98,2", ["E", "N", "X", "N", "n"]
      return true if response[2].split(",")[3].to_i != 0
      false
    end

    def lock
      @controller.send_cmd ">N#{@address}SS98,1,255", ["E", "N", "X", "N", "n"] 
    end

    def unlock
      @controller.send_cmd ">N#{@address}SS98,1,0", ["E", "N", "X", "N", "n"]
    end
  end
end
