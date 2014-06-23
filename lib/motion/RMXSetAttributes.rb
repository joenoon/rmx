module RMXSetAttributes

  def self.included(klass)
    klass.send(:include, InstanceMethods)
    klass.send(:extend, ClassMethods)
  end

  module InstanceMethods

    def after_attributes_set
    end

    def attributes=(attrs={})
      keys = [] + attrs.keys
      while key = keys.pop
        value = attrs[key]
        self.send("#{key}=", value)
      end
      after_attributes_set
    end

  end

  module ClassMethods

    def create(opts={})
      x = new
      x.attributes = opts
      x
    end

  end

end
