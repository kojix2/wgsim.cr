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
        index = 0
        deletions = [] of UInt8
        event_log = [] of EventRecord

        slice = sequence.map do |nucleotide|
          index += 1 # 1-based index
          if previous_ref_base_is_deletion?(deletions)
            if extend_deletion?
              base = delete_nucleotide(nucleotide, deletions)
              next base
            else # stop deletion
              # NOTE: should stop when n is N?
              log_deletion(event_log, deletions, index)
              deletions.clear
            end
          end

          # skip N
          next nochange_nucleotide(nucleotide) if nucleotide == 78u8

          case pick_mutation_type
          when MutType::SUBSTITUTE
            substitute_nucleotide(nucleotide, event_log, index)
          when MutType::INSERT
            insert_nucleotide(nucleotide, event_log, index)
          when MutType::DELETE
            delete_nucleotide(nucleotide, deletions)
          else
            nochange_nucleotide(nucleotide)
          end
        end
        if previous_ref_base_is_deletion?(deletions)
          log_deletion(event_log, deletions, index, end_of_sequence: true)
          deletions.clear
        end
        {RefSeq.new(slice), event_log}
      end

      private def previous_ref_base_is_deletion?(deletions : Array(UInt8)) : Bool
        deletions.present?
      end

      private def extend_deletion? : Bool
        rand < deletion_extension_probability
      end

      private def pick_mutation_type : MutType
        value = rand
        if value <= substitution_rate
          MutType::SUBSTITUTE
        elsif value <= (substitution_rate + insertion_rate)
          MutType::INSERT
        elsif value <= (substitution_rate + insertion_rate + deletion_rate)
          MutType::DELETE
        else
          MutType::NOCHANGE
        end
      end

      def nochange_nucleotide(n : UInt8) : RefBase
        RefBase.new(nucleotide: n, mutation_type: MutType::NOCHANGE)
      end

      def insert_nucleotide(n : UInt8, event_log : Array(EventRecord), index : Int32) : RefBase
        ins = generate_insertion
        log_insertion(event_log, index, n, ins)
        RefBase.new(nucleotide: n, mutation_type: MutType::INSERT, insertion: ins)
      end

      def delete_nucleotide(n : UInt8, deletions : Array(UInt8)) : RefBase
        deletions << n
        RefBase.new(nucleotide: n, mutation_type: MutType::DELETE)
      end

      def substitute_nucleotide(n : UInt8, event_log : Array(EventRecord), index : Int32) : RefBase
        nn = perform_substitution(n, rand(3))
        log_substitution(event_log, index, n, nn)
        RefBase.new(nucleotide: nn, mutation_type: MutType::SUBSTITUTE)
      end

      def log_deletion(event_log : Array(EventRecord), deletions : Array(UInt8), index : Int32, end_of_sequence : Bool = false) : Nil
        delseq = String.build do |io|
          deletions.each { |deleted_base| io.write_byte(deleted_base) }
        end
        position = if end_of_sequence
                     index - deletions.size + 1
                   else
                     index - deletions.size
                   end
        event_log << EventRecord.new(MutType::DELETE, position, delseq, '.')
      end

      def log_substitution(event_log : Array(EventRecord), index : Int32, n : UInt8, nn : UInt8) : Nil
        event_log << EventRecord.new(MutType::SUBSTITUTE, index, n.chr, nn.chr)
      end

      def log_insertion(event_log : Array(EventRecord), index : Int32, n : UInt8, ins : Slice(UInt8)) : Nil
        alt_seq = String.build do |io|
          io << n.chr
          io.write(ins)
        end
        event_log << EventRecord.new(MutType::INSERT, index, n.chr, alt_seq)
      end
    end
  end
end
