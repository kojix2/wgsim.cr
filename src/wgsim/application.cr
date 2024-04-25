require "randn"
require "./ref_base"
require "./mutate/action"
require "./sequence/action"

module Wgsim
  class Application
    @option : Mutate::Option | Sequence::Option

    def initialize(@option)
    end

    def run
      case @option
      when Mutate::Option
        Mutate::Action.run(@option.as(Mutate::Option))
      when Sequence::Option
        Sequence::Action.run(@option.as(Sequence::Option))
      else
        raise "Unknown command"
      end
    end
  end
end
