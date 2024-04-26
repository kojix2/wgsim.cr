require "randn"

module Wgsim
  class Mutate
    class Core
      delegate rand, randn, to: @random

      property mutation_rate : Float64
      property indel_fraction : Float64
      property indel_extension_probability : Float64
      property seed : UInt64?

      ACGT = StaticArray[65u8, 67u8, 71u8, 84u8]
      CGT  = StaticArray[67u8, 71u8, 84u8]
      AGT  = StaticArray[65u8, 71u8, 84u8]
      ACT  = StaticArray[65u8, 67u8, 84u8]
      ACG  = StaticArray[65u8, 67u8, 71u8]

      def initialize(
        @mutation_rate,
        @indel_fraction,
        @indel_extension_probability,
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

      def perform_substitution(nucleotide : UInt8) : UInt8
        case nucleotide
        when 65u8 # A
          CGT[rand(3)]
        when 67u8 # C
          AGT[rand(3)]
        when 71u8 # G
          ACT[rand(3)]
        when 84u8 # T
          ACG[rand(3)]
        else # N
          78u8
        end
      end

      # Generate insertion based on given size and indel extension probability
      def generate_insertion : Slice(UInt8)
        size = 1
        while rand <= indel_extension_probability
          size += 1
        end
        Slice(UInt8).new(size) { ACGT[rand(4)] }
      end

      # Simulate mutations and output the results
      # Returns a slice of RefBase

      def simulate_mutations(@name : String, sequence : Slice(UInt8)) : Slice(RefBase)
        sequence.map do |n|
          @index += 1 # 1-based index
          if previous_ref_base_is_deletion?
            if extend_deletion?
              base = delete_nucleotide(n)
              next base
            else # stop deletion
              log_deletion
              @deletions.clear
            end
          end

          if mutation_occurs? && n != 78u8 # N
            mutate_nucleotide(n)
          else
            nochange_nucleotide(n)
          end
        end
      end

      private def previous_ref_base_is_deletion? : Bool
        @deletions.present?
      end

      private def extend_deletion? : Bool
        rand < indel_extension_probability
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
        nn = perform_substitution(n)
        log_substitution(n, nn)
        RefBase.new(nucleotide: nn, mutation_type: MutType::SUBSTITUTE)
      end

      def mutate_nucleotide(n) : RefBase
        case rand
        when indel_fraction..
          substitute_nucleotide(n)
        when (indel_fraction / 2)..
          insert_nucleotide(n)
        else # deletion
          delete_nucleotide(n)
        end
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
