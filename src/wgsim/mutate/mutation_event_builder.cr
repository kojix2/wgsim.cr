require "./mutation_event"

module Wgsim
  class Mutate
    # Converts internal mutation state into event-log records.
    #
    # Keeping this separate from MutationSimulator makes a useful distinction
    # for readers: the simulator decides what happened, while this builder
    # decides how that event is written down.
    module MutationEventBuilder
      def self.deletion(
        deleted_bases : Array(UInt8),
        reference_position : Int32,
        end_of_sequence : Bool = false,
      ) : MutationEvent
        # The simulator accumulates deleted bases as bytes. The event log is
        # human-readable, so convert the deleted run back into a DNA string.
        deleted_sequence = String.build do |io|
          deleted_bases.each { |deleted_base| io.write_byte(deleted_base) }
        end

        # reference_position points at the first base after the deletion when
        # the deletion closes. At end-of-sequence there is no following base,
        # so the coordinate calculation is different by one base.
        deletion_start_position = if end_of_sequence
                                    reference_position - deleted_bases.size + 1
                                  else
                                    reference_position - deleted_bases.size
                                  end
        MutationEvent.new(
          mutation_type: MutationType::DELETE,
          reference_position: deletion_start_position,
          reference_allele: deleted_sequence,
          alternate_allele: '.'
        )
      end

      def self.substitution(
        reference_position : Int32,
        reference_base : UInt8,
        alternate_base : UInt8,
      ) : MutationEvent
        MutationEvent.new(
          mutation_type: MutationType::SUBSTITUTE,
          reference_position: reference_position,
          reference_allele: reference_base.chr,
          alternate_allele: alternate_base.chr
        )
      end

      def self.insertion(
        reference_position : Int32,
        reference_base : UInt8,
        inserted_bases : Slice(UInt8),
      ) : MutationEvent
        # Insertions are represented as reference base + inserted sequence in
        # the alternate allele. This mirrors the common VCF convention of
        # anchoring an insertion to the preceding reference base.
        alternate_allele = String.build do |io|
          io << reference_base.chr
          io.write(inserted_bases)
        end
        MutationEvent.new(
          mutation_type: MutationType::INSERT,
          reference_position: reference_position,
          reference_allele: reference_base.chr,
          alternate_allele: alternate_allele
        )
      end
    end
  end
end
