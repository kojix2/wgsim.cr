require "fastx"
require "./console"
require "./sequencing/fastq_record"
require "./sequencing/option"
require "./sequencing/error_model"
require "./sequencing/read_pair_simulator"

module Wgsim
  class Sequencing
    getter option : Option
    getter reference : Path
    getter read1_fastq : Path
    getter read2_fastq : Path
    getter read_pair_simulator : ReadPairSimulator

    def self.run(option)
      new(option).run
    end

    def initialize(@option : Option)
      @reference = sequencing_options.reference || raise(ArgumentError.new("Reference sequence is required"))
      @read1_fastq = sequencing_options.read1_fastq || raise(ArgumentError.new("Output FASTQ file 1 is required"))
      @read2_fastq = sequencing_options.read2_fastq || raise(ArgumentError.new("Output FASTQ file 2 is required"))
      sequencing_options.validate!
      @read_pair_simulator = ReadPairSimulator.new(
        average_depth: sequencing_options.average_depth,
        mean_insert_size: sequencing_options.mean_insert_size,
        insert_size_std_dev: sequencing_options.insert_size_std_dev,
        read1_length: sequencing_options.read1_length,
        read2_length: sequencing_options.read2_length,
        error_rate: sequencing_options.error_rate,
        max_ambiguous_ratio: sequencing_options.max_ambiguous_ratio,
        seed: sequencing_options.seed
      )
    end

    private def sequencing_options
      @option
    end

    def run
      Fastx::Fastq::Writer.open(read1_fastq) do |read1_writer|
        Fastx::Fastq::Writer.open(read2_fastq) do |read2_writer|
          Fastx::Fasta::Reader.open(reference) do |reader|
            reader.each_bytes do |name, sequence|
              name_string = String.new(name)
              read_pair_simulator.simulate_read_pairs(name_string, sequence) do |record1, record2|
                read1_writer.write(record1.identifier, record1.read_sequence, record1.quality_sequence)
                read2_writer.write(record2.identifier, record2.read_sequence, record2.quality_sequence)
              end
              Console.info("#{name_string} done")
            end
          end
        end
      end
    end
  end
end
