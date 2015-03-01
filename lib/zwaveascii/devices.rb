module ZWave
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
end
