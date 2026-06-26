require "./ref_base"

module Wgsim
  class RefSeq
    DEFAULT_FASTA_LINE_WIDTH = 80

    def initialize(@reference_bases : Slice(RefBase))
    end

    forward_missing_to @reference_bases

    def format(width : Int = DEFAULT_FASTA_LINE_WIDTH) : String
      seq = IO::Memory.new
      @reference_bases.each do |ref_base|
        case ref_base.mutation_type
        when MutType::NOCHANGE, MutType::SUBSTITUTE
          seq.write_byte ref_base.nucleotide
        when MutType::DELETE
        when MutType::INSERT
          seq.write_byte ref_base.nucleotide
          ins = ref_base.insertion
          seq.write ins if ins
        end
      end
      format_sequence(seq, width: width)
    end

    private def format_sequence(sequence : IO::Memory, width : Int) : String
      sequence.to_s.gsub(/(.{#{width}})/, "\\1\n")
    end
  end
end
