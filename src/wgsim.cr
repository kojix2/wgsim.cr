require "./crystal_scheduler"
require "./wgsim/version"
require "./wgsim/options"
require "./wgsim/parser"
require "./wgsim/app"

module Wgsim
  def self.run
    options = Wgsim::Parser.new.parse
    simulator = Wgsim::Simulator.new(options)
    simulator.run
  end
end
