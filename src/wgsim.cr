require "./crystal_scheduler"
require "./wgsim/version"
require "./wgsim/config"
require "./wgsim/parser"
require "./wgsim/app"

module Wgsim
  def self.run
    config = Wgsim::Parser.new.parse
    simulator = Wgsim::Simulator.new(config)
    simulator.run
  end
end
