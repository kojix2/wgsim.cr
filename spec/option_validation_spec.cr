require "./spec_helper"

describe "option validation" do
  it "rejects invalid mutation rates" do
    option = Wgsim::Mutate::Option.new
    option.substitution_rate = 0.8
    option.insertion_rate = 0.2
    option.deletion_rate = 0.1

    expect_raises(ArgumentError, /sum/) do
      option.validate!
    end
  end

  it "rejects zero ploidy" do
    option = Wgsim::Mutate::Option.new
    option.ploidy = 0

    expect_raises(ArgumentError, /Ploidy/) do
      option.validate!
    end
  end

  it "rejects invalid sequence error rates" do
    option = Wgsim::Sequence::Option.new
    option.error_rate = 0.0

    expect_raises(ArgumentError, /error rate/) do
      option.validate!
    end
  end

  it "rejects invalid read sizes" do
    option = Wgsim::Sequence::Option.new
    option.read1_length = 0

    expect_raises(ArgumentError, /Read 1 length/) do
      option.validate!
    end
  end

  it "rejects invalid generated chromosome lengths" do
    option = Wgsim::Generate::Option.new
    option.chromosome_lengths = [1000, 0]

    expect_raises(ArgumentError, /Chromosome length/) do
      option.validate!
    end
  end
end
