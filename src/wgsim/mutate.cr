require "fastx"
require "./log"
require "./mutate/option"
require "./mutate/mutation_simulator"

module Wgsim
  class Mutate
    getter option : Option
    getter reference : Path
    getter mutated_fasta : Path
    getter mutation_event_log : Path # Should be a VCF in the future
    getter mutation_simulator : MutationSimulator

    def self.run(option)
      new(option).run
    end

    def initialize(@option : Option)
      @reference = option.reference || raise(ArgumentError.new("Reference sequence is required"))
      @mutated_fasta = option.mutated_fasta || raise(ArgumentError.new("Output FASTA file is required"))
      @mutation_event_log = option.mutation_event_log || raise(ArgumentError.new("Output mutation file is required"))
      option.validate!
      @mutation_simulator = MutationSimulator.new(
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
        Log.info("# #{line}")
      end
    end

    private def process_sequences
      Fastx::Fasta::Reader.open(reference) do |reader|
        Fastx::Fasta::Writer.open(mutated_fasta, line_width: ReferenceSequence::DEFAULT_FASTA_LINE_WIDTH) do |fasta_writer|
          File.open(mutation_event_log, "w") do |mutation_io|
            reader.each_bytes do |name, sequence|
              name_string = String.new(name)
              Log.info("#{name_string} #{sequence.size} bp")
              process_sequence(name_string, sequence, fasta_writer: fasta_writer, mutation_io: mutation_io)
            end
          end
        end
      end
    end

    private def process_sequence(reference_name : String, reference_sequence : Bytes, fasta_writer : Fastx::Fasta::Writer, mutation_io : IO)
      if option.ploidy == 1
        simulate_and_output_sequence(reference_name, reference_sequence, fasta_writer: fasta_writer, mutation_io: mutation_io)
      else
        option.ploidy.times do |copy_index|
          simulate_and_output_sequence(reference_name, reference_sequence, copy_index + 1, fasta_writer: fasta_writer, mutation_io: mutation_io)
        end
      end
    end

    private def simulate_and_output_sequence(reference_name : String, reference_sequence : Slice(UInt8), copy_number = nil, *, fasta_writer : Fastx::Fasta::Writer, mutation_io = STDERR)
      output_sequence_name = "#{reference_name.split.first}"
      output_sequence_name += "_#{copy_number}" if copy_number
      mutated_sequence, event_log = mutation_simulator.simulate_mutations(reference_sequence)
      event_log.each do |mutation_event|
        mutation_event.sequence_name = output_sequence_name
        mutation_event.to_s(mutation_io)
        mutation_io.puts
      end
      fasta_writer.write(output_sequence_name, mutated_sequence.to_slice)
    end
  end
end
