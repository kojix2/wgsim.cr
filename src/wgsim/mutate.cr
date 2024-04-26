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
      begin
        reader.each do |name, sequence|
          STDERR.puts "[wgsim] #{name} #{sequence.size} bp"
          process_sequence(name, sequence)
        end
      rescue ex
        STDERR.puts "Error processing sequences: #{ex.message}"
      ensure
        reader.try &.close
      end
    end

    private def process_sequence(name : String, sequence : IO::Memory)
      reference_sequence = Fastx.normalize_sequence(sequence)
      if option.ploidy == 1
        simulate_and_output_sequence(name, reference_sequence)
      else
        option.ploidy.times { |i| simulate_and_output_sequence(name, reference_sequence, i + 1) }
      end
    end

    private def simulate_and_output_sequence(name : String, reference_sequence : Slice(UInt8), index = nil)
      pname = "#{name.split.first}"
      pname += "_#{index}" if index
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
      puts format_sequence(seq)
    end

    private def format_sequence(sequence : IO::Memory) : String
      sequence.to_s.gsub(/(.{80})/, "\\1\n")
    end
  end
end
