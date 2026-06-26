require "./fasta_formatter"
require "./generate/option"
require "./generate/random_reference_generator"

module Wgsim
  class Generate
    FASTA_LINE_WIDTH = FastaFormatter::DEFAULT_LINE_WIDTH

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
        puts FastaFormatter.wrap(sequence, FASTA_LINE_WIDTH)
        # puts
      end
    end
  end
end
