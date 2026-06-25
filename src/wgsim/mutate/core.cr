require "randn"
require "../core_utils"
require "./event_record"

module Wgsim
  class Mutate
    class Core
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
        # buffer for deletion
        @deletions = [] of UInt8
        # index of the current nucleotide
        @index = 0
        # mutation event log
        @event_log = [] of EventRecord
      end

      # Generate insertion based on given size and indel extension probability
      def generate_insertion : Slice(UInt8)
        size = 1
        while rand <= insertion_extension_probability
          size += 1
        end
        Slice(UInt8).new(size) { ACGT[rand(4)] }
      end

      # Simulate mutations and output the results
      # Returns a slice of RefBase

      def simulate_mutations(sequence : Slice(UInt8)) : {RefSeq, Array(EventRecord)}
        @index = 0
        @event_log = [] of EventRecord
        slice = sequence.map do |nucleotide|
          @index += 1 # 1-based index
          if previous_ref_base_is_deletion?
            if extend_deletion?
              base = delete_nucleotide(nucleotide)
              next base
            else # stop deletion
              # NOTE: should stop when n is N?
              log_deletion
              @deletions.clear
            end
          end

          # skip N
          next nochange_nucleotide(nucleotide) if nucleotide == 78u8

          case rand
          when ..substitution_rate
            substitute_nucleotide(nucleotide)
          when ..(substitution_rate + insertion_rate)
            insert_nucleotide(nucleotide)
          when ..(substitution_rate + insertion_rate + deletion_rate)
            delete_nucleotide(nucleotide)
          else
            nochange_nucleotide(nucleotide)
          end
        end
        if previous_ref_base_is_deletion?
          log_deletion(end_of_sequence: true)
          @deletions.clear
        end
        {RefSeq.new(slice), @event_log}
      end

      private def previous_ref_base_is_deletion? : Bool
        @deletions.present?
      end

      private def extend_deletion? : Bool
        rand < deletion_extension_probability
      end

      private def mutation_occurs? : Bool
        rand < mutation_rate
      end

      private def deletion_occurs?(n) : Bool
        rand < (indel_fraction / 2)
      end

      def nochange_nucleotide(n : UInt8) : RefBase
        RefBase.new(nucleotide: n, mutation_type: MutType::NOCHANGE)
      end

      def insert_nucleotide(n : UInt8) : RefBase
        ins = generate_insertion
        log_insertion(n, ins)
        RefBase.new(nucleotide: n, mutation_type: MutType::INSERT, insertion: ins)
      end

      def delete_nucleotide(n : UInt8) : RefBase
        @deletions << n
        RefBase.new(nucleotide: n, mutation_type: MutType::DELETE)
      end

      def substitute_nucleotide(n : UInt8) : RefBase
        nn = perform_substitution(n, rand(3))
        log_substitution(n, nn)
        RefBase.new(nucleotide: nn, mutation_type: MutType::SUBSTITUTE)
      end

      def log_deletion(end_of_sequence : Bool = false) : Nil
        delseq = String.build do |io|
          @deletions.each { |deleted_base| io.write_byte(deleted_base) }
        end
        position = if end_of_sequence
                     @index - @deletions.size + 1
                   else
                     @index - @deletions.size
                   end
        @event_log << EventRecord.new(MutType::DELETE, position, delseq, '.')
      end

      def log_substitution(n, nn) : Nil
        @event_log << EventRecord.new(MutType::SUBSTITUTE, @index, n.chr, nn.chr)
      end

      def log_insertion(n, ins) : Nil
        alt_seq = String.build do |io|
          io << n.chr
          io.write(ins)
        end
        @event_log << EventRecord.new(MutType::INSERT, @index, n.chr, alt_seq)
      end
    end
  end
end
