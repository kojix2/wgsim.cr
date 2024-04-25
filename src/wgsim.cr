require "nworkers"
require "./wgsim/version"
require "./wgsim/parser"
require "./wgsim/application"

module Wgsim
  def self.run
    parser = Wgsim::Parser.new
    option = parser.parse
    app = Wgsim::Application.new(option)
    app.run
  end
end
