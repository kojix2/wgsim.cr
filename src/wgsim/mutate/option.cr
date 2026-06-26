module Wgsim
  class Mutate
    class Option
      property reference : Path?
      property ploidy : UInt8 = 2
      property seed : UInt64?
      property substitution_rate : Float64 = 0.001
      property insertion_rate : Float64 = 0.0001
      property deletion_rate : Float64 = 0.0001
      property insertion_extension_probability : Float64 = 0.3
      property deletion_extension_probability : Float64 = 0.3
      property output_fasta : Path?
      property output_mutation : Path? # Should be a VCF in the future

      def summary
        <<-SUMMARY
        Reference: #{reference}
        Ploidy: #{ploidy}
        Seed: #{seed.nil? ? "random" : seed}
        Substitution rate: #{substitution_rate}
        Insertion    rate: #{insertion_rate}
        Deletion     rate: #{deletion_rate}
        Insertion extension probability: #{insertion_extension_probability}
        Deletion  extension probability: #{deletion_extension_probability}
        SUMMARY
      end

      def validate! : Nil
        raise ArgumentError.new("Ploidy must be at least 1") if ploidy < 1

        validate_probability("substitution rate", substitution_rate)
        validate_probability("insertion rate", insertion_rate)
        validate_probability("deletion rate", deletion_rate)
        validate_probability("insertion extension probability", insertion_extension_probability)
        validate_probability("deletion extension probability", deletion_extension_probability)

        total_rate = substitution_rate + insertion_rate + deletion_rate
        if total_rate > 1.0
          raise ArgumentError.new("The sum of substitution, insertion, and deletion rates must be <= 1.0")
        end
      end

      private def validate_probability(name : String, value : Float64) : Nil
        unless value >= 0.0 && value <= 1.0
          raise ArgumentError.new("#{name} must be between 0.0 and 1.0")
        end
      end
    end
  end
end
