module Wgsim
  module Mutate
    class Option
      property seed : UInt64?
      property mutation_rate : Float64 = 0.001
      property indel_fraction : Float64 = 0.15
      property indel_extension_probability : Float64 = 0.3
      property reference : Path?
    end
  end
end
