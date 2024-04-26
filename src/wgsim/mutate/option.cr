module Wgsim
  class Mutate
    class Option
      property seed : UInt64?
      property substitution_rate : Float64 = 0.001
      property insertion_rate : Float64 = 0.0001
      property deletion_rate : Float64 = 0.0001
      property insertion_extension_probability : Float64 = 0.3
      property deletion_extension_probability : Float64 = 0.3
      property reference : Path?
    end
  end
end
