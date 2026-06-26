require "fastx"
require "./console"
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
      Console.summary(option.summary)
      writer = Fastx::Fasta::Writer.new(STDOUT, line_width: FASTA_LINE_WIDTH)
      reference_generator.generate_sequences do |name, sequence|
        writer.write(name, sequence)
      end
    end
  end
end
