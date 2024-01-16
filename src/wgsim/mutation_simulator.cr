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
      # FIXME: output file should be configurable ?
      log_mutation(name, index, nucleotide, new_nucleotide)
      new_nucleotide
    end

    def log_mutation(name : String, index : Int32, old_nucleotide : UInt8, new_nucleotide : UInt8)
      STDERR.puts "[wgsim] #{name} #{index} #{old_nucleotide.chr} -> #{new_nucleotide.chr}"
    end

    def generate_insertion : Slice(UInt8)
      String.build do |s|
        while _rand < indel_extension_probability
          s << ['A', 'C', 'G', 'T'].sample
        end
      end.to_slice
    end

    # This method mutates in haploid and may not be suitable for
    # germline mutations that are common in the population

    def simulate_mutations(name : String, sequence : Slice(RefBase)) : Slice(RefBase)
      deleting = false
      sequence.map_with_index do |c, i|
        if deleting
          if _rand < indel_extension_probability
            # continue deletion
            next RefBase.new(nucleotide: c.nucleotide, mutation_type: MutType::DELETE)
          else
            # stop deletion
            deleting = false
          end
        end
        if _rand < mutation_rate
          if _rand > indel_fraction
            # substitution
            nn = perform_substitution(c.nucleotide, name, i)
            RefBase.new(nucleotide: nn, mutation_type: MutType::SUBSTITUTE)
          elsif _rand < 0.5
            # deletion
            deleting = true
            RefBase.new(nucleotide: c.nucleotide, mutation_type: MutType::DELETE)
          else
            # insertion
            ins = generate_insertion
            RefBase.new(nucleotide: c.nucleotide, mutation_type: MutType::INSERT, insertion: ins)
          end
        else
          c # no mutation
        end
      end
    end
  end
end
