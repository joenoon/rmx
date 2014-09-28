class RACSignal

  def self.combineLatestOrEmpty(signals)
    if signals.any?
      combineLatest(signals)
    else
      RACSignal.return(RACTuple.tupleWithObjectsFromArray([]))
    end
  end

end
