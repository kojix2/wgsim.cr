require "randn"
require "../core_utils"
require "./mutation_event"

module Wgsim
  class Mutate
    class MutationSimulator
      include CoreUtils
      delegate rand, randn, to: @random

      property substitution_rate : Float64
      property insertion_rate : Float64
      property deletion_rate : Float64
      property insertion_extension_probability : Float64
      property deletion_extension_probability : Float64
      property seed : UInt64?

      def initialize(
        @substitution_rate,
        @insertion_rate,
        @deletion_rate,
        @insertion_extension_probability,
        @deletion_extension_probability,
        @seed : UInt64? = nil,
      )
        # random number generator with seed
        seed = @seed
        @random = seed ? Rand.new(seed) : Rand.new
      end

      # Generate inserted bases based on the insertion extension probability.
      def generate_inserted_bases : Slice(UInt8)
        inserted_base_count = 1
        while rand <= insertion_extension_probability
          inserted_base_count += 1
        end
        Slice(UInt8).new(inserted_base_count) { DNA_BASES[rand(DNA_BASES.size)] }
      end

      def simulate_mutations(sequence : Slice(UInt8)) : {ReferenceSequence, Array(MutationEvent)}
        reference_position = 0
        deleted_bases = [] of UInt8
        event_log = [] of MutationEvent

        mutated_bases = sequence.map do |reference_base|
          reference_base = normalize_base(reference_base)
          reference_position += 1 # 1-based reference position
          if deletion_is_open?(deleted_bases)
            if extend_current_deletion?
              deleted_base = build_deleted_reference_base(reference_base, deleted_bases)
              next deleted_base
            else # stop deletion
              # NOTE: should stop when n is N?
              log_deletion(event_log, deleted_bases, reference_position)
              deleted_bases.clear
            end
          end

          # skip N
          next build_unchanged_reference_base(reference_base) if reference_base == BASE_N

          case pick_mutation_type
          when MutationType::SUBSTITUTE
            build_substituted_reference_base(reference_base, event_log, reference_position)
          when MutationType::INSERT
            build_insertion_reference_base(reference_base, event_log, reference_position)
          when MutationType::DELETE
            build_deleted_reference_base(reference_base, deleted_bases)
          else
            build_unchanged_reference_base(reference_base)
          end
        end
        if deletion_is_open?(deleted_bases)
          log_deletion(event_log, deleted_bases, reference_position, end_of_sequence: true)
          deleted_bases.clear
        end
        {ReferenceSequence.new(mutated_bases), event_log}
      end

      private def deletion_is_open?(deleted_bases : Array(UInt8)) : Bool
        deleted_bases.present?
      end

      private def extend_current_deletion? : Bool
        rand < deletion_extension_probability
      end

      private def pick_mutation_type : MutationType
        value = rand
        if value <= substitution_rate
          MutationType::SUBSTITUTE
        elsif value <= (substitution_rate + insertion_rate)
          MutationType::INSERT
        elsif value <= (substitution_rate + insertion_rate + deletion_rate)
          MutationType::DELETE
        else
          MutationType::NOCHANGE
        end
      end

      def build_unchanged_reference_base(reference_base : UInt8) : ReferenceBase
        ReferenceBase.new(nucleotide: reference_base, mutation_type: MutationType::NOCHANGE)
      end

      def build_insertion_reference_base(reference_base : UInt8, event_log : Array(MutationEvent), reference_position : Int32) : ReferenceBase
        inserted_bases = generate_inserted_bases
        log_insertion(event_log, reference_position, reference_base, inserted_bases)
        ReferenceBase.new(nucleotide: reference_base, mutation_type: MutationType::INSERT, insertion: inserted_bases)
      end

      def build_deleted_reference_base(reference_base : UInt8, deleted_bases : Array(UInt8)) : ReferenceBase
        deleted_bases << reference_base
        ReferenceBase.new(nucleotide: reference_base, mutation_type: MutationType::DELETE)
      end

      def build_substituted_reference_base(reference_base : UInt8, event_log : Array(MutationEvent), reference_position : Int32) : ReferenceBase
        alternate_base = perform_substitution(reference_base, rand(SUBSTITUTIONS_FOR_A.size))
        log_substitution(event_log, reference_position, reference_base, alternate_base)
        ReferenceBase.new(nucleotide: alternate_base, mutation_type: MutationType::SUBSTITUTE)
      end

      def log_deletion(event_log : Array(MutationEvent), deleted_bases : Array(UInt8), reference_position : Int32, end_of_sequence : Bool = false) : Nil
        deleted_sequence = String.build do |io|
          deleted_bases.each { |deleted_base| io.write_byte(deleted_base) }
        end
        deletion_start_position = if end_of_sequence
                                    reference_position - deleted_bases.size + 1
                                  else
                                    reference_position - deleted_bases.size
                                  end
        event_log << MutationEvent.new(MutationType::DELETE, deletion_start_position, deleted_sequence, '.')
      end

      def log_substitution(event_log : Array(MutationEvent), reference_position : Int32, reference_base : UInt8, alternate_base : UInt8) : Nil
        event_log << MutationEvent.new(MutationType::SUBSTITUTE, reference_position, reference_base.chr, alternate_base.chr)
      end

      def log_insertion(event_log : Array(MutationEvent), reference_position : Int32, reference_base : UInt8, inserted_bases : Slice(UInt8)) : Nil
        alternate_allele = String.build do |io|
          io << reference_base.chr
          io.write(inserted_bases)
        end
        event_log << MutationEvent.new(MutationType::INSERT, reference_position, reference_base.chr, alternate_allele)
      end
    end
  end
end
