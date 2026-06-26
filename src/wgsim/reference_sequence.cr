require "./fasta_formatter"
require "./reference_base"

module Wgsim
  class ReferenceSequence
    DEFAULT_FASTA_LINE_WIDTH = FastaFormatter::DEFAULT_LINE_WIDTH

    def initialize(@reference_bases : Slice(ReferenceBase))
    end

    forward_missing_to @reference_bases

    def format(width : Int = DEFAULT_FASTA_LINE_WIDTH) : String
      seq = IO::Memory.new
      @reference_bases.each do |reference_base|
        case reference_base.mutation_type
        when MutationType::NOCHANGE, MutationType::SUBSTITUTE
          seq.write_byte reference_base.nucleotide
        when MutationType::DELETE
        when MutationType::INSERT
          seq.write_byte reference_base.nucleotide
          ins = reference_base.insertion
          seq.write ins if ins
        end
      end
      FastaFormatter.wrap(seq, width: width)
    end
  end
end
