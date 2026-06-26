require "./reference_base"

module Wgsim
  class ReferenceSequence
    DEFAULT_FASTA_LINE_WIDTH = 80

    def initialize(@reference_bases : Slice(ReferenceBase))
    end

    forward_missing_to @reference_bases

    def to_slice : Bytes
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
      seq.to_slice
    end

    def format(width : Int = DEFAULT_FASTA_LINE_WIDTH) : String
      raise ArgumentError.new("width must be positive") if width <= 0

      sequence = to_slice

      String.build do |io|
        start = 0
        while start < sequence.size
          chunk_size = Math.min(width, sequence.size - start)
          io.write(sequence[start, chunk_size])
          io << '\n' if chunk_size == width
          start += chunk_size
        end
      end
    end
  end
end
