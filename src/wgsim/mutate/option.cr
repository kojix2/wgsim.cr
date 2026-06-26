module Wgsim
  class Mutate
    class Option
      MIN_PROBABILITY = 0.0
      MAX_PROBABILITY = 1.0

      DEFAULT_PLOIDY                          =    2u8
      DEFAULT_SUBSTITUTION_RATE               =  0.001
      DEFAULT_INSERTION_RATE                  = 0.0001
      DEFAULT_DELETION_RATE                   = 0.0001
      DEFAULT_INSERTION_EXTENSION_PROBABILITY =    0.3
      DEFAULT_DELETION_EXTENSION_PROBABILITY  =    0.3

      property reference : Path?
      property ploidy : UInt8 = DEFAULT_PLOIDY
      property seed : UInt64?
      property substitution_rate : Float64 = DEFAULT_SUBSTITUTION_RATE
      property insertion_rate : Float64 = DEFAULT_INSERTION_RATE
      property deletion_rate : Float64 = DEFAULT_DELETION_RATE
      property insertion_extension_probability : Float64 = DEFAULT_INSERTION_EXTENSION_PROBABILITY
      property deletion_extension_probability : Float64 = DEFAULT_DELETION_EXTENSION_PROBABILITY
      property mutated_fasta : Path?
      property mutation_event_log : Path? # Should be a VCF in the future

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
        if total_rate > MAX_PROBABILITY
          raise ArgumentError.new("The sum of substitution, insertion, and deletion rates must be <= #{MAX_PROBABILITY}")
        end
      end

      private def validate_probability(name : String, value : Float64) : Nil
        unless value >= MIN_PROBABILITY && value <= MAX_PROBABILITY
          raise ArgumentError.new("#{name} must be between #{MIN_PROBABILITY} and #{MAX_PROBABILITY}")
        end
      end
    end
  end
end
