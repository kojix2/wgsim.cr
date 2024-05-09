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
      @reference = sopts.reference.not_nil!
      @output1 = sopts.output1.not_nil!
      @output2 = sopts.output2.not_nil!
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
          normalized_sequence = Fastx.normalize_sequence(sequence)
          core.run(name, normalized_sequence) do |record1, record2|
            output_fasta_1.puts record1.to_s
            output_fasta_2.puts record2.to_s
          end
          STDERR.puts "[wgsim] #{name} done"
        end
      end

      output_fasta_1.close
      output_fasta_2.close
    end
  end
end
