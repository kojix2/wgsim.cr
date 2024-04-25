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
      else
        raise ArgumentError.new("Invalid action")
      end
    rescue ex
      error_message = "[wgsim.cr] ERROR: #{ex.class} #{ex.message}"
      error_message += "\n#{ex.backtrace.join("\n")}" if CLI.debug
      STDERR.puts error_message
      exit(1)
    end
  end
end
