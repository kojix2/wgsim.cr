require "./reference_base"

module Wgsim
  # A mutable-style view of a reference sequence after mutation simulation.
  #
  # The simulator first records each reference position as a ReferenceBase.
  # This class then flattens those records into the final FASTA sequence.
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
          # Deleted bases remain in the event log but are omitted from FASTA.
        when MutationType::INSERT
          seq.write_byte reference_base.nucleotide
          ins = reference_base.insertion
          seq.write ins if ins
        end
      end
      seq.to_slice
    end
  end
end
