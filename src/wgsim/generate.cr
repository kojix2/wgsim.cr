require "./generate/option"
require "./generate/random_reference_generator"

module Wgsim
  class Generate
    FASTA_LINE_WIDTH = 80

    getter option : Option
    getter reference_generator : RandomReferenceGenerator

    def self.run(option)
      new(option).run
    end

    def initialize(@option : Option)
      option.validate!
      @reference_generator = RandomReferenceGenerator.new(
        chromosome_lengths: option.chromosome_lengths,
        seed: option.seed
      )
    end

    def run
      reference_generator.generate_sequences do |name, sequence|
        puts ">#{name}"
        puts wrap_fasta_sequence(sequence, FASTA_LINE_WIDTH)
        # puts
      end
    end

    private def wrap_fasta_sequence(sequence : Slice(UInt8), width : Int) : String
      IO::Memory.new(sequence).to_s.gsub(/(.{#{width}})/, "\\1\n")
    end
  end
end
