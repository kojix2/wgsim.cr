require "randn"
require "./ref_base"
require "./ref_seq"
require "./sample_sheet"
require "./mutate"
require "./sequence"
require "./generate"

module Wgsim
  class CLI
    class_property debug : Bool = false
    getter parser : Parser
    getter action : Action?
    getter option : (Mutate::Option | Sequence::Option | Generate::Option)?

    private def mopt
      @option.as(Mutate::Option)
    end

    private def sopt
      @option.as(Sequence::Option)
    end

    private def gopt
      @option.as(Generate::Option)
    end

    def initialize
      @parser = Parser.new
      @action, @option = @parser.parse(ARGV)
    end

    def run
      case action
      when Action::Mutate
        Mutate.run(mopt)
      when Action::Sequence
        Sequence.run(sopt)
      when Action::Generate
        Generate.run(gopt)
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
