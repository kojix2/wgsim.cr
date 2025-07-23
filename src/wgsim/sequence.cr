require "fastx"
require "./sequence/fastq_record"
require "./sequence/option"
require "./sequence/core"

module Wgsim
  class Sequence
    getter option : Option
    getter reference : Path
    getter output1 : Path
    getter output2 : Path
    getter core : Core

    def self.run(option)
      new(option).run
    end

    def initialize(@option : Option)
      @reference = sopts.reference || raise("Reference sequence is required")
      @output1 = sopts.output1 || raise("Output FASTQ file 1 is required")
      @output2 = sopts.output2 || raise("Output FASTQ file 2 is required")
      @core = Core.new(
        average_depth: sopts.average_depth,
        distance: sopts.distance,
        std_deviation: sopts.std_deviation,
        size_left: sopts.size_left,
        size_right: sopts.size_right,
        error_rate: sopts.error_rate,
        max_ambiguous_ratio: sopts.max_ambiguous_ratio,
        seed: sopts.seed
      )
    end

    private def sopts
      @option
    end

    def run
      output_fasta_1 = File.open(output1, "w")
      output_fasta_2 = File.open(output2, "w")

      Fastx::Fasta::Reader.open(reference) do |reader|
        reader.each do |name, sequence|
          normalized_sequence = sequence.to_slice
          core.run(name, normalized_sequence) do |record1, record2|
            output_fasta_1.puts record1.to_s
            output_fasta_2.puts record2.to_s
          end
          STDERR.puts "[wgsim] #{name} done"
        end
      end
    ensure
      output_fasta_1.try &.close
      output_fasta_2.try &.close
    end
  end
end
