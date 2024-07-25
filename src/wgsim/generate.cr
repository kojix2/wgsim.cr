require "./generate/option"
require "./generate/core"

module Wgsim
  class Generate
    getter option : Option
    getter core : Core

    def self.run(option)
      new(option).run
    end

    def initialize(@option : Option)
      @core = Core.new(
        chromosome_length: option.chromosome_length,
        seed: option.seed
      )
    end

    def run
      core.generate_sequence do |name, sequence|
        puts ">#{name}"
        puts format_sequence(sequence, 80)
        # puts
      end
    end

    private def format_sequence(sequence : Slice(UInt8), width : Int) : String
      IO::Memory.new(sequence).to_s.gsub(/(.{#{width}})/, "\\1\n")
    end
  end
end
