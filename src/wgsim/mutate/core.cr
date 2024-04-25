require "randn"

module Wgsim
  class Mutate
    # This module provides a simple simulator for mutations in a DNA sequence.
    class Core
      delegate _rand, randn, rand_bool, to: @random

      property mutation_rate : Float64
      property indel_fraction : Float64
      property indel_extension_probability : Float64
      property seed : UInt64?

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

      ACGT = StaticArray[65u8, 67u8, 71u8, 84u8]
      CGT  = StaticArray[67u8, 71u8, 84u8]
      AGT  = StaticArray[65u8, 71u8, 84u8]
      ACT  = StaticArray[65u8, 67u8, 84u8]
      ACG  = StaticArray[65u8, 67u8, 71u8]

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

      def generate_insertion : Slice(UInt8)
        siz = 1
        while _rand <= indel_extension_probability
          siz += 1
        end
        Slice(UInt8).new(siz) { ACGT.sample }
      end

      # This method mutates in haploid and may not be suitable for
      # germline mutations that are common in the population

      def simulate_mutations(name : String, sequence : Slice(UInt8)) : Slice(RefBase)
        deleting = [] of UInt8
        sequence.map_with_index do |n, i|
          # i is 0-based
          if deleting.present?
            if _rand < indel_extension_probability
              # continue deletion
              deleting << n
              next RefBase.new(nucleotide: n, mutation_type: MutType::DELETE)
            else
              # stop deletion
              delseq = deleting.map { |n| n.chr }.join
              STDERR.puts ["[wgsim]", "DEL", name, i - deleting.size + 1, delseq, "."].join("\t")
              deleting.clear
            end
          end
          if _rand < mutation_rate && n != 78u8 # N
            if _rand > indel_fraction
              # substitution
              nn = perform_substitution(n)
              STDERR.puts ["[wgsim]", "SUB", name, i + 1, n.chr, nn.chr].join("\t")
              RefBase.new(nucleotide: nn, mutation_type: MutType::SUBSTITUTE)
            elsif _rand < 0.5
              # deletion
              deleting << n
              RefBase.new(nucleotide: n, mutation_type: MutType::DELETE)
            else
              # insertion
              ins = generate_insertion
              STDERR.puts ["[wgsim]", "INS", name, i + 1, n.chr, n.chr + String.new(ins)].join("\t")
              RefBase.new(nucleotide: n, mutation_type: MutType::INSERT, insertion: ins)
            end
          else
            RefBase.new(nucleotide: n, mutation_type: MutType::NOCHANGE)
          end
        end
      end
    end
  end
end
