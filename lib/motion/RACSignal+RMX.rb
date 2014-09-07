class RACSignal

  def self.combineLatestOrEmpty(signals)
    if signals.any?
      combineLatest(signals)
    else
      RACSignal.return(RACTuple.tupleWithObjectsFromArray([]))
    end
  end

end


class RACStream

  def rmxLogNext(name)
    if RMX::Env["RAC_DEBUG_SIGNAL_NAMES"]
      setNameWithFormat(name).logNext
    else
      self
    end
  end

end
