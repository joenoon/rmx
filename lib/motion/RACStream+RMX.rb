class RACStream

  # provides a convenient way to expand a RACTuple to an Array.
  #
  # the default way of working with a RACTuple in ruby:
  #
  #   signal_that_nexts_tuple
  #   .subscribeNext(->(tuple) {
  #     p "tuple:", tuple
  #     p "tuple.allObjects:", tuple.allObjects
  #     arg0 = tuple[0]
  #     arg1 = tuple[1]
  #     # ... do stuff with arg0 and arg1 ...
  #   })
  #
  # changing it to an array doesnt change much at first glance:
  #
  #   signal_that_nexts_tuple
  #   .rmx_expandTuple
  #   .subscribeNext(->(array) {
  #     p "array:", array
  #     arg0 = array[0]
  #     arg1 = array[1]
  #     # ... do stuff with arg0 and arg1 ...
  #   })
  #
  # but, in ruby, a proc's argument syntax can capitalize on arrays:
  #
  #   signal_that_nexts_tuple
  #   .rmx_expandTuple
  #   .subscribeNext(->((arg0, arg1)) {
  #     # ... do stuff with arg0 and arg1 ...
  #   })
  #
  def rmx_expandTuple
    map(->(tuple) { tuple.allObjects }.weak!)
  end

end
