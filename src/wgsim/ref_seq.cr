require "./ref_base"

module Wgsim
  class RefSeq
    def initialize(@slice : Slice(RefBase))
    end

    forward_missing_to @slice

    def format(width : Int = 80) : String
      seq = IO::Memory.new
      @slice.each do |b|
        case b.mutation_type
        when MutType::NOCHANGE, MutType::SUBSTITUTE
          seq.write_byte b.nucleotide
        when MutType::DELETE
        when MutType::INSERT
          seq.write_byte b.nucleotide
          ins = b.insertion
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
