require "fastx"
require "./mutate/option"
require "./mutate/core"

module Wgsim
  class Mutate
    getter option : Option
    getter reference : Path
    getter core : Core

    def self.run(option)
      new(option).run
    end

    def initialize(@option : Option)
      @reference = option.reference.not_nil!
      @core = Core.new(
        substitution_rate: option.substitution_rate,
        insertion_rate: option.insertion_rate,
        deletion_rate: option.deletion_rate,
        insertion_extension_probability: option.insertion_extension_probability,
        deletion_extension_probability: option.deletion_extension_probability,
        seed: option.seed
      )
    end

    def run
      log_parameters
      process_sequences
    end

    private def log_parameters
      option.summary.split("\n").each do |line|
        STDERR.puts "[wgsim] # #{line}"
      end
    end

    private def process_sequences
      reader = Fastx::Fasta::Reader.new(reference)
      reader.each do |name, sequence|
        STDERR.puts "[wgsim] #{name} #{sequence.size} bp"
        process_sequence(name, sequence)
      end
    ensure
      reader.try &.close
    end

    private def process_sequence(name : String, sequence : IO::Memory)
      reference_sequence = Fastx.normalize_sequence(sequence)
      # Diploid
      2.times do |i|
        simulate_and_output_sequence(name, i, reference_sequence)
      end
    end

    private def simulate_and_output_sequence(name : String, index : Int32, reference_sequence : Slice(UInt8))
      pname = "#{name.split.first}_#{index}"
      puts ">#{pname}"
      mutated_sequence = core.simulate_mutations(pname, reference_sequence)
      output_mutated_sequence(mutated_sequence)
    end

    private def output_mutated_sequence(mutated_sequence)
      seq = IO::Memory.new
      mutated_sequence.each do |b|
        case b.mutation_type
        when MutType::NOCHANGE, MutType::SUBSTITUTE
          seq.write_byte b.nucleotide
        when MutType::DELETE
        when MutType::INSERT
          seq.write_byte b.nucleotide
          ins = b.insertion
          seq.write ins if ins
        end
      end
      puts seq.to_s.gsub(/(.{80})/, "\\1\n")
    end
  end
end
