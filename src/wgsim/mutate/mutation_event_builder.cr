require "./mutation_event"

module Wgsim
  class Mutate
    module MutationEventBuilder
      def self.deletion(deleted_bases : Array(UInt8), reference_position : Int32, end_of_sequence : Bool = false) : MutationEvent
        deleted_sequence = String.build do |io|
          deleted_bases.each { |deleted_base| io.write_byte(deleted_base) }
        end
        deletion_start_position = if end_of_sequence
                                    reference_position - deleted_bases.size + 1
                                  else
                                    reference_position - deleted_bases.size
                                  end
        MutationEvent.new(MutationType::DELETE, deletion_start_position, deleted_sequence, '.')
      end

      def self.substitution(reference_position : Int32, reference_base : UInt8, alternate_base : UInt8) : MutationEvent
        MutationEvent.new(MutationType::SUBSTITUTE, reference_position, reference_base.chr, alternate_base.chr)
      end

      def self.insertion(reference_position : Int32, reference_base : UInt8, inserted_bases : Slice(UInt8)) : MutationEvent
        alternate_allele = String.build do |io|
          io << reference_base.chr
          io.write(inserted_bases)
        end
        MutationEvent.new(MutationType::INSERT, reference_position, reference_base.chr, alternate_allele)
      end
    end
  end
end
