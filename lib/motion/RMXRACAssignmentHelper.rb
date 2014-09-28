# used internally by RMX#rac helper
class RMXRACAssignmentHelper
  def initialize(trampoline, keypath)
    @trampoline = trampoline
    @keypath = keypath
  end

  def signal=(signal)
    @trampoline[@keypath] = signal
  end
end
