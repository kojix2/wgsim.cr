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
        @random = \
           if @seed
             Rand.new(@seed.not_nil!)
           else
             Rand.new
           end
      end

      def perform_substitution(nucleotide : UInt8) : UInt8
        case nucleotide
        when 65u8 # A
          CGT.sample
        when 67u8 # C
          AGT.sample
        when 71u8 # G
          ACT.sample
        when 84u8 # T
          ACG.sample
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
        Slice(UInt8).new(size) { ACGT.sample }
      end

      # Simulate mutations and output the results
      def simulate_mutations(name : String, sequence : Slice(UInt8)) : Slice(RefBase)
        deletions = [] of UInt8
        sequence.map_with_index do |n, i|
          # i is 0-based
          if deletions.present?
            if rand < indel_extension_probability
              # continue deletion
              deletions << n
              next RefBase.new(nucleotide: n, mutation_type: MutType::DELETE)
            else
              # stop deletion
              log_deletion(name, i, deletions)
              deletions.clear
            end
          end

          if mutation_occurs? && n != 78u8 # N
            log_mutation(name, i, n, deletions)
          else
            RefBase.new(nucleotide: n, mutation_type: MutType::NOCHANGE)
          end
        end
      end

      def mutation_occurs?
        rand < mutation_rate
      end

      def log_mutation(name, i, n, deletions)
        if rand > indel_fraction
          # substitution
          nn = perform_substitution(n)
          log_substitution(name, i, n, nn)
          RefBase.new(nucleotide: nn, mutation_type: MutType::SUBSTITUTE)
        elsif rand < 0.5
          # deletion
          deletions << n
          RefBase.new(nucleotide: n, mutation_type: MutType::DELETE)
        else
          # insertion
          ins = generate_insertion
          log_insertion(name, i, n, ins)
          RefBase.new(nucleotide: n, mutation_type: MutType::INSERT, insertion: ins)
        end
      end

      def log_deletion(name, index, deletions)
        delseq = deletions.map { |n| n.chr }.join
        STDERR.puts ["[wgsim]", "DEL", name, index - deletions.size + 1, delseq, "."].join("\t")
      end

      def log_substitution(name, index, n, nn)
        STDERR.puts ["[wgsim]", "SUB", name, index + 1, n.chr, nn.chr].join("\t")
      end

      def log_insertion(name, index, n, ins)
        STDERR.puts ["[wgsim]", "INS", name, index + 1, n.chr, n.chr + String.new(ins)].join("\t")
      end
    end
  end
end
