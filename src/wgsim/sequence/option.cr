module Wgsim
  class Sequence
    class Option
      property seed : UInt64?
      property error_rate : Float64 = 0.02
      property distance : Int32 = 500
      property std_deviation : Int32 = 50
      property average_depth : Float64 = 10
      property size_left : Int32 = 70
      property size_right : Int32 = 70
      property mutation_rate : Float64 = 0.001
      property indel_fraction : Float64 = 0.15
      property indel_extension_probability : Float64 = 0.3
      property max_ambiguous_ratio : Float64 = 0.05
      property reference : Path?
      property output1 : Path?
      property output2 : Path?

      def summary
        <<-SUMMARY
        Reference: #{reference}
        Seed: #{seed.nil? ? "random" : seed}
        Error rate: #{error_rate}
        Distance between reads: #{distance}
        Standard deviation of distance: #{std_deviation}
        Average depth of coverage: #{average_depth}
        Read size (left): #{size_left}
        Read size (right): #{size_right}
        Mutation rate: #{mutation_rate}
        Indel fraction: #{indel_fraction}
        Indel extension probability: #{indel_extension_probability}
        Maximum ambiguous base ratio: #{max_ambiguous_ratio}
        Output file 1: #{output1}
        Output file 2: #{output2}
        SUMMARY
      end
    end
  end
end
