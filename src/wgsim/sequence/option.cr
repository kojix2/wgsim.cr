module Wgsim
  class Sequence
    class Option
      property seed : UInt64?
      property error_rate : Float64 = 0.01
      property distance : Int32 = 500
      property std_deviation : Int32 = 50
      property average_depth : Float64 = 10
      property size_left : Int32 = 100
      property size_right : Int32 = 100
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

      def validate! : Nil
        validate_probability("error rate", error_rate, allow_zero: false)
        validate_probability("maximum ambiguous base ratio", max_ambiguous_ratio)

        raise ArgumentError.new("Distance between reads must be greater than 0") if distance <= 0
        raise ArgumentError.new("Standard deviation must be >= 0") if std_deviation < 0
        raise ArgumentError.new("Average depth must be >= 0.0") if average_depth < 0.0
        raise ArgumentError.new("Read size left must be greater than 0") if size_left <= 0
        raise ArgumentError.new("Read size right must be greater than 0") if size_right <= 0
      end

      private def validate_probability(name : String, value : Float64, allow_zero : Bool = true) : Nil
        lower_bound_ok = allow_zero ? value >= 0.0 : value > 0.0
        unless lower_bound_ok && value <= 1.0
          lower_bound = allow_zero ? "0.0" : "greater than 0.0"
          raise ArgumentError.new("#{name} must be #{lower_bound} and <= 1.0")
        end
      end
    end
  end
end
