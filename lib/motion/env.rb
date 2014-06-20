module RMExtensions

  DEBUG_LONGTASK = Env['rmext_debug_longtask'] == '1'
  DEBUG_DEALLOC = Env['rmext_debug_dealloc'] == '1'
  DEBUG_EVENTS = Env['rmext_debug_events'] == '1'
  DEBUG_QUEUES = Env['rmext_debug_queues'] == '1'
  DEBUG = Env['rmext_debug'] == '1'

end
