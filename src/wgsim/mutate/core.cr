require "randn"
require "../core_utils"

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
        @seed : UInt64? = nil
      )
        # random number generator with seed
        @random = \
           if @seed
             Rand.new(@seed.not_nil!)
           else
             Rand.new
           end
        # buffer for deletion
        @deletions = [] of UInt8
        # name of the current sequence
        @name = ""
        # index of the current nucleotide
        @index = 0
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

      def simulate_mutations(@name : String, sequence : Slice(UInt8)) : Slice(RefBase)
        @index = 0
        sequence.map do |n|
          @index += 1 # 1-based index
          if previous_ref_base_is_deletion?
            if extend_deletion?
              base = delete_nucleotide(n)
              next base
            else # stop deletion
              # NOTE: should stop when n is N?
              log_deletion
              @deletions.clear
            end
          end

          # skip N
          next nochange_nucleotide(n) if n == 78u8

          case rand
          when ..substitution_rate
            substitute_nucleotide(n)
          when ..(substitution_rate + insertion_rate)
            insert_nucleotide(n)
          when ..(substitution_rate + insertion_rate + deletion_rate)
            delete_nucleotide(n)
          else
            nochange_nucleotide(n)
          end
        end
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

      def log_deletion : Nil
        delseq = @deletions.map { |n| n.chr }.join
        STDERR.puts ["[wgsim]", "DEL", @name, @index - @deletions.size, delseq, "."].join("\t")
      end

      def log_substitution(n, nn) : Nil
        STDERR.puts ["[wgsim]", "SUB", @name, @index, n.chr, nn.chr].join("\t")
      end

      def log_insertion(n, ins) : Nil
        STDERR.puts ["[wgsim]", "INS", @name, @index, n.chr, n.chr + String.new(ins)].join("\t")
      end
    end
  end
end
