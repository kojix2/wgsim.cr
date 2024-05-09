require "./spec_helper"

describe Wgsim::CLI do
  it "has debug class variable" do
    Wgsim::CLI.debug.should be_false
  end
end
