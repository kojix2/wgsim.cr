require "randn"
require "./reference_base"
require "./reference_sequence"
require "./mutate"
require "./sequencing"
require "./generate"

module Wgsim
  class CLI
    class_property? debug : Bool = false
    getter parser : Parser
    getter action : Action?
    getter option : (Mutate::Option | Sequencing::Option | Generate::Option)?

    private def mutation_options
      @option.as(Mutate::Option)
    end

    private def sequencing_options
      @option.as(Sequencing::Option)
    end

    private def generation_options
      @option.as(Generate::Option)
    end

    def initialize
      @parser = Parser.new
      @action, @option = @parser.parse(ARGV)
    end

    def run
      case action
      when Action::Mutate
        Mutate.run(mutation_options)
      when Action::Sequencing
        Sequencing.run(sequencing_options)
      when Action::Generate
        Generate.run(generation_options)
      when Action::Version
        print_version
      when Action::Help
        print_help
      when nil
        print_help_and_exit
      else
        raise ArgumentError.new("Invalid action: #{action || "nil"}")
      end
    end

    def print_version
      puts "#{PROGRAM_NAME} #{VERSION}"
    end

    def print_help
      puts parser.help_message
    end

    def print_help_and_exit
      print_help
      exit 1
    end
  end
end
