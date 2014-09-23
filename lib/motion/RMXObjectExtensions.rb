module RMXObjectExtensions

  module Helper
    def self.rmx_object_desc(obj)
      if obj
        cname = obj.className.to_s
        obj_id = '%x' % obj.object_id.to_i
        res = "#<#{cname}:0x#{obj_id}>"
      end
    end
  end
    
  def rmx_object_desc
    Helper.rmx_object_desc(self)
  end

  def rmx_log_dealloc(verbose=false)
    ::RMX.log_dealloc(self, verbose)
    self
  end

end
Object.send(:include, RMXObjectExtensions)
