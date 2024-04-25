require "randn"
require "./ref_base"
require "./mutate/action"
require "./sequence/action"

module Wgsim
  class CLI
    class_property debug : Bool = false
    getter parser : Parser
    getter option : Mutate::Option | Sequence::Option

    def initialize
      @parser = Parser.new
      @option = @parser.parse(ARGV)
    end

    def run
      case @option
      when Mutate::Option
        Mutate::Action.run(@option.as(Mutate::Option))
      when Sequence::Option
        Sequence::Action.run(@option.as(Sequence::Option))
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
