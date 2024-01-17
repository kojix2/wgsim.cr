require "./ext/crystal_scheduler"
require "./wgsim/version"
require "./wgsim/options"
require "./wgsim/parser"
require "./wgsim/application"

module Wgsim
  def self.run
    options = Wgsim::Parser.new.parse
    app = Wgsim::Application.new(options)
    app.run
  end
end
