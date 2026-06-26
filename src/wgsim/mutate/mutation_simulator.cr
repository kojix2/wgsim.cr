require "randn"
require "../dna"
require "./mutation_event_builder"
require "./mutation_event"
require "./mutation_type_sampler"

module Wgsim
  class Mutate
    class MutationSimulator
      include Dna
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
        seed = @seed
        @random = seed ? Rand.new(seed) : Rand.new
        @mutation_type_sampler = MutationTypeSampler.new(
          substitution_rate: substitution_rate,
          insertion_rate: insertion_rate,
          deletion_rate: deletion_rate,
          random: @random
        )
      end

      # Generate inserted bases based on the insertion extension probability.
      def generate_inserted_bases : Slice(UInt8)
        inserted_base_count = 1
        # An insertion always starts with one new base. The extension
        # probability then makes longer insertions geometrically distributed.
        while rand < insertion_extension_probability
          inserted_base_count += 1
        end
        Slice(UInt8).new(inserted_base_count) { DNA_BASES[rand(DNA_BASES.size)] }
      end

      def simulate_mutations(sequence : Slice(UInt8)) : {ReferenceSequence, Array(MutationEvent)}
        reference_position = 0
        open_deletion_bases = [] of UInt8
        mutation_events = [] of MutationEvent

        # map keeps one ReferenceBase per input reference base. Inserted bases
        # are attached later to a ReferenceBase instead of becoming separate
        # reference positions.
        mutated_bases = sequence.map do |reference_base|
          reference_base = normalize_base(reference_base)
          reference_position += 1 # 1-based reference position

          # A deletion can span multiple adjacent bases. While it is open,
          # each following reference base either extends the same event or
          # closes the event before normal mutation sampling resumes.
          if deletion_is_open?(open_deletion_bases)
            if deletion_extends_to_next_base?
              deleted_base = build_deleted_reference_base(
                reference_base: reference_base,
                deleted_bases: open_deletion_bases
              )
              next deleted_base
            else
              close_open_deletion(
                deleted_bases: open_deletion_bases,
                reference_position: reference_position,
                mutation_events: mutation_events
              )
            end
          end

          # Ambiguous bases are emitted unchanged and excluded from mutation sampling.
          if ambiguous_base?(reference_base)
            next build_unchanged_reference_base(reference_base: reference_base)
          end

          case @mutation_type_sampler.sample
          when MutationType::SUBSTITUTE
            build_substituted_reference_base(
              reference_base: reference_base,
              mutation_events: mutation_events,
              reference_position: reference_position
            )
          when MutationType::INSERT
            build_insertion_reference_base(
              reference_base: reference_base,
              mutation_events: mutation_events,
              reference_position: reference_position
            )
          when MutationType::DELETE
            build_deleted_reference_base(
              reference_base: reference_base,
              deleted_bases: open_deletion_bases
            )
          else
            build_unchanged_reference_base(reference_base: reference_base)
          end
        end

        if deletion_is_open?(open_deletion_bases)
          close_open_deletion(
            deleted_bases: open_deletion_bases,
            reference_position: reference_position,
            mutation_events: mutation_events,
            end_of_sequence: true
          )
        end

        {ReferenceSequence.new(mutated_bases), mutation_events}
      end

      private def ambiguous_base?(reference_base : UInt8) : Bool
        reference_base == BASE_N
      end

      private def deletion_is_open?(deleted_bases : Array(UInt8)) : Bool
        deleted_bases.present?
      end

      private def deletion_extends_to_next_base? : Bool
        rand < deletion_extension_probability
      end

      private def close_open_deletion(
        deleted_bases : Array(UInt8),
        reference_position : Int32,
        mutation_events : Array(MutationEvent),
        end_of_sequence : Bool = false,
      ) : Nil
        mutation_events << MutationEventBuilder.deletion(
          deleted_bases: deleted_bases,
          reference_position: reference_position,
          end_of_sequence: end_of_sequence
        )
        deleted_bases.clear
      end

      def build_unchanged_reference_base(reference_base : UInt8) : ReferenceBase
        ReferenceBase.new(nucleotide: reference_base, mutation_type: MutationType::NOCHANGE)
      end

      def build_insertion_reference_base(
        reference_base : UInt8,
        mutation_events : Array(MutationEvent),
        reference_position : Int32,
      ) : ReferenceBase
        inserted_bases = generate_inserted_bases
        mutation_events << MutationEventBuilder.insertion(
          reference_position: reference_position,
          reference_base: reference_base,
          inserted_bases: inserted_bases
        )
        ReferenceBase.new(
          nucleotide: reference_base,
          mutation_type: MutationType::INSERT,
          insertion: inserted_bases
        )
      end

      def build_deleted_reference_base(
        reference_base : UInt8,
        deleted_bases : Array(UInt8),
      ) : ReferenceBase
        deleted_bases << reference_base
        ReferenceBase.new(nucleotide: reference_base, mutation_type: MutationType::DELETE)
      end

      def build_substituted_reference_base(
        reference_base : UInt8,
        mutation_events : Array(MutationEvent),
        reference_position : Int32,
      ) : ReferenceBase
        alternate_base = perform_substitution(
          base: reference_base,
          substitution_index: rand(SUBSTITUTIONS_FOR_A.size)
        )
        mutation_events << MutationEventBuilder.substitution(
          reference_position: reference_position,
          reference_base: reference_base,
          alternate_base: alternate_base
        )
        ReferenceBase.new(nucleotide: alternate_base, mutation_type: MutationType::SUBSTITUTE)
      end
    end
  end
end
