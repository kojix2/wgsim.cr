require "../dna"

module Wgsim
  class Sequencing
    class ErrorModel
      include Dna

      PHRED_ASCII_OFFSET =  33
      PHRED_SCORE_FACTOR = -10

      def initialize(@error_rate : Float64, @random : Rand)
      end

      def quality_char : Char
        ((PHRED_ASCII_OFFSET + (PHRED_SCORE_FACTOR * Math.log10(@error_rate))).round).to_u8.chr
      end

      def add_errors(sequence : Slice(UInt8)) : Slice(UInt8)
        sequence.map do |base|
          if (base != BASE_N) && (@random.rand < @error_rate)
            perform_substitution(base, @random.rand(SUBSTITUTIONS_FOR_A.size))
          else
            base
          end
        end
      end
    end
  end
end
