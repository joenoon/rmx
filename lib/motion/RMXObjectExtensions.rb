module RMXObjectExtensions
    
  def rmx_object_desc
    cname = self.className.to_s
    obj_id = '%x' % (self.object_id + 0)
    res = "#<#{cname}:0x#{obj_id}>"
  end

end
Object.send(:include, RMXObjectExtensions)
