require "./rand"

module Wgsim
  class MutationSimulator
    delegate _rand, rand_norm, rand_bool, to: @random
    getter mutation_rate : Float64
    getter indel_fraction : Float64
    getter indel_extension_probability : Float64

    def initialize(
      @mutation_rate,
      @indel_fraction,
      @indel_extension_probability,
      @random = Rand.new
    )
    end

    def perform_substitution(nucleotide : UInt8, name : String, index : Int32) : UInt8
      new_nucleotide =
        case nucleotide
        when 65u8 # A
          [67u8, 71u8, 84u8].sample
        when 67u8 # C
          [65u8, 71u8, 84u8].sample
        when 71u8 # G
          [65u8, 67u8, 84u8].sample
        when 84u8 # T
          [65u8, 67u8, 71u8].sample
        else # N
          78u8
        end
      new_nucleotide
    end

    def generate_insertion : Slice(UInt8)
      String.build do |s|
        loop do
          s << ['A', 'C', 'G', 'T'].sample
          break if _rand > indel_extension_probability
        end
      end.to_slice
    end

    # This method mutates in haploid and may not be suitable for
    # germline mutations that are common in the population

    def simulate_mutations(name : String, sequence : Slice(RefBase)) : Slice(RefBase)
      deleting = [] of UInt8
      sequence.map_with_index do |c, i|
        # i is 0-based
        if deleting.present?
          if _rand < indel_extension_probability
            # continue deletion
            n = c.nucleotide
            deleting << n
            next RefBase.new(nucleotide: n, mutation_type: MutType::DELETE)
          else
            # stop deletion
            delseq = deleting.map { |n| n.chr }.join
            STDERR.puts ["[wgsim]", "DEL", name, i - deleting.size + 1, delseq, "."].join("\t")
            deleting.clear
          end
        end
        if _rand < mutation_rate
          n = c.nucleotide
          if _rand > indel_fraction
            # substitution
            nn = perform_substitution(n, name, i)
            STDERR.puts ["[wgsim]", "SUB", name, i + 1, n.chr, nn.chr].join("\t")
            RefBase.new(nucleotide: nn, mutation_type: MutType::SUBSTITUTE)
          elsif _rand < 0.5
            # deletion
            deleting << n
            # STDERR.puts ["[wgsim]", "DEL", name, i, n.chr, "."].join("\t")
            RefBase.new(nucleotide: n, mutation_type: MutType::DELETE)
          else
            # insertion
            ins = generate_insertion
            STDERR.puts ["[wgsim]", "INS", name, i + 1, n.chr, n.chr + String.new(ins)].join("\t")
            RefBase.new(nucleotide: n, mutation_type: MutType::INSERT, insertion: ins)
          end
        else
          c # no mutation
        end
      end
    end
  end
end
