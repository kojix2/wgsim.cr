require "randn"
require "./ref_base"
require "./mutate"
require "./sequence"

module Wgsim
  class CLI
    class_property debug : Bool = false
    getter parser : Parser
    getter action : Action?
    getter option : (Mutate::Option | Sequence::Option)?

    private def mopt
      @option.as(Mutate::Option)
    end

    private def sopt
      @option.as(Sequence::Option)
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
      when Action::Version
        print_version
      when Action::Help
        print_help
      else
        raise ArgumentError.new("Invalid action: #{action || "nil"}")
      end
    end

    def print_version
      puts Wgsim::VERSION
    end

    def print_help
      puts parser.help_message
    end
  end
end
