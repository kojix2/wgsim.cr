require "fastx"
require "./sequence/option"
require "./sequence/core"

module Wgsim
  class Sequence
    def self.run(option)
      new(option).run
    end

    def initialize(@option : Option)
    end

    private def sopts
      @option
    end

    def run
      reference = sopts.reference.not_nil!
      output1 = sopts.output1.not_nil!
      output2 = sopts.output2.not_nil!

      sequence_simulator = Core.new(
        sopts.average_depth,
        sopts.distance,
        sopts.std_deviation,
        sopts.size_left,
        sopts.size_right,
        sopts.error_rate,
        sopts.max_ambiguous_ratio,
        sopts.seed
      )

      output_fasta_1 = File.open(output1, "w")
      output_fasta_2 = File.open(output2, "w")

      names = [] of String
      channel = Channel(String).new

      Fastx::Fasta::Reader.open(reference) do |reader|
        reader.each do |name, sequence|
          names << name
          normalized_sequence = Fastx.normalize_sequence(sequence)
          spawn do
            sequence_simulator.run(name, normalized_sequence) do |record1, record2|
              output_fasta_1.puts record1
              output_fasta_2.puts record2
            end
            channel.send name
          end
        end
      end

      while names.present?
        name = channel.receive
        names.delete name
        STDERR.puts "[wgsim] #{name} done"
      end

      output_fasta_1.close
      output_fasta_2.close
    end
  end
end
