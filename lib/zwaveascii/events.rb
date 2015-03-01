module ZWave
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
