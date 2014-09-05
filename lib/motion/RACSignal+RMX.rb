class RACSignal

  def self.combineLatestOrEmpty(signals)
    if signals.any?
      combineLatest(signals)
    else
      RACSignal.return(RACTuple.tupleWithObjectsFromArray([]))
    end
  end

  def self.combineLatestOrEmptyToArray(signals)
    if signals.any?
      combineLatest(signals)
      .flattenMap(->(tuple) {
        RACSignal.return(tuple.allObjects)
      })
    else
      RACSignal.return([])
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
