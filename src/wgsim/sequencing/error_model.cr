require "../dna"

module Wgsim
  class Sequencing
    # A simple sequencing-error model.
    #
    # This class represents observation errors made by the sequencer, not
    # biological mutations in the genome. It only substitutes A/C/G/T bases;
    # ambiguous N bases remain N because their true base is unknown.
    class ErrorModel
      include Dna

      PHRED_ASCII_OFFSET =  33
      PHRED_SCORE_FACTOR = -10

      def initialize(@error_rate : Float64, @random : Rand)
      end

      # FASTQ qualities encode error probability as an ASCII character.
      # Here we use one uniform quality character for every base in a read.
      def quality_char : Char
        ((PHRED_ASCII_OFFSET + (PHRED_SCORE_FACTOR * Math.log10(@error_rate))).round).to_u8.chr
      end

      def add_errors(sequence : Slice(UInt8)) : Slice(UInt8)
        sequence.map do |base|
          # Sequencing errors are sampled independently per observed base.
          if (base != BASE_N) && (@random.rand < @error_rate)
            perform_substitution(
              base: base,
              substitution_index: @random.rand(SUBSTITUTIONS_FOR_A.size)
            )
          else
            base
          end
        end
      end
    end
  end
end
