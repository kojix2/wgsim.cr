require "fastx"
require "./sequence/fastq_record"
require "./sequence/option"
require "./sequence/sequencing_error_model"
require "./sequence/read_pair_simulator"

module Wgsim
  class Sequence
    getter option : Option
    getter reference : Path
    getter read1_fastq : Path
    getter read2_fastq : Path
    getter read_pair_simulator : ReadPairSimulator

    def self.run(option)
      new(option).run
    end

    def initialize(@option : Option)
      @reference = sopts.reference || raise("Reference sequence is required")
      @read1_fastq = sopts.read1_fastq || raise("Output FASTQ file 1 is required")
      @read2_fastq = sopts.read2_fastq || raise("Output FASTQ file 2 is required")
      sopts.validate!
      @read_pair_simulator = ReadPairSimulator.new(
        average_depth: sopts.average_depth,
        mean_insert_size: sopts.mean_insert_size,
        insert_size_std_dev: sopts.insert_size_std_dev,
        read1_length: sopts.read1_length,
        read2_length: sopts.read2_length,
        error_rate: sopts.error_rate,
        max_ambiguous_ratio: sopts.max_ambiguous_ratio,
        seed: sopts.seed
      )
    end

    private def sopts
      @option
    end

    def run
      read1_fastq_io = File.open(read1_fastq, "w")
      read2_fastq_io = File.open(read2_fastq, "w")

      Fastx::Fasta::Reader.open(reference) do |reader|
        reader.each_bytes do |name, sequence|
          name_string = String.new(name)
          read_pair_simulator.simulate_read_pairs(name_string, sequence) do |record1, record2|
            record1.to_s(read1_fastq_io)
            record2.to_s(read2_fastq_io)
          end
          STDERR.puts "[wgsim] #{name_string} done"
        end
      end
    ensure
      read1_fastq_io.try &.close
      read2_fastq_io.try &.close
    end
  end
end
