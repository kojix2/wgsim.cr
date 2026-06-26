require "fastx"
require "./mutate/option"
require "./mutate/core"

module Wgsim
  class Mutate
    getter option : Option
    getter reference : Path
    getter mutated_fasta : Path
    getter mutation_event_log : Path # Should be a VCF in the future
    getter core : Core

    def self.run(option)
      new(option).run
    end

    def initialize(@option : Option)
      @reference = option.reference || raise("Reference sequence is required")
      @mutated_fasta = option.mutated_fasta || raise("Output FASTA file is required")
      @mutation_event_log = option.mutation_event_log || raise("Output mutation file is required")
      option.validate!
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
      fasta_io = File.open(mutated_fasta, "w")
      mutation_io = File.open(mutation_event_log, "w")
      begin
        reader.each_bytes do |name, sequence|
          name_string = String.new(name)
          STDERR.puts "[wgsim] #{name_string} #{sequence.size} bp"
          process_sequence(name_string, sequence, fasta_io: fasta_io, mutation_io: mutation_io)
        end
      ensure
        reader.try &.close
        fasta_io.try &.close
        mutation_io.try &.close
      end
    end

    private def process_sequence(reference_name : String, reference_sequence : Bytes, fasta_io : IO, mutation_io : IO)
      if option.ploidy == 1
        simulate_and_output_sequence(reference_name, reference_sequence, fasta_io: fasta_io, mutation_io: mutation_io)
      else
        option.ploidy.times do |copy_index|
          simulate_and_output_sequence(reference_name, reference_sequence, copy_index + 1, fasta_io: fasta_io, mutation_io: mutation_io)
        end
      end
    end

    private def simulate_and_output_sequence(reference_name : String, reference_sequence : Slice(UInt8), copy_number = nil, fasta_io = STDOUT, mutation_io = STDERR)
      output_sequence_name = "#{reference_name.split.first}"
      output_sequence_name += "_#{copy_number}" if copy_number
      fasta_io.puts ">#{output_sequence_name}"
      mutated_sequence, event_log = core.simulate_mutations(reference_sequence)
      event_log.each do |event_record|
        event_record.sequence_name = output_sequence_name
        event_record.to_s(mutation_io)
        mutation_io.puts
      end
      fasta_io.puts mutated_sequence.format
    end
  end
end
