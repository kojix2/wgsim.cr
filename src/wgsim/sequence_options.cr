module Wgsim
  struct SequenceOptions
    property error_rate : Float64 = 0.02
    property distance : Int32 = 500
    property std_deviation : Int32 = 50
    property mean_depth : Float64 = 10
    property size_left : Int32 = 70
    property size_right : Int32 = 70
    property mutation_rate : Float64 = 0.001
    property indel_fraction : Float64 = 0.15
    property indel_extension_probability : Float64 = 0.3
    property max_ambiguous_ratio : Float64 = 0.05
    property reference : Path?
    property output1 : Path?
    property output2 : Path?
  end
end
