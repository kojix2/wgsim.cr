require "./spec_helper"

class FixedRandom
  def initialize(@value : Float64)
  end

  def rand : Float64
    @value
  end
end

describe Wgsim::Mutate::MutationTypeSampler do
  it "samples mutation types from cumulative mutation probabilities" do
    sampler = Wgsim::Mutate::MutationTypeSampler.new(
      substitution_rate: 1.0,
      insertion_rate: 0.0,
      deletion_rate: 0.0,
      random: Rand.new(1u64)
    )

    sampler.sample.should eq Wgsim::MutationType::SUBSTITUTE
  end

  it "treats cumulative probability boundaries as the start of the next interval" do
    substitution_boundary = Wgsim::Mutate::MutationTypeSampler.new(
      substitution_rate: 0.1,
      insertion_rate: 0.2,
      deletion_rate: 0.3,
      random: FixedRandom.new(0.1)
    )
    insertion_boundary = Wgsim::Mutate::MutationTypeSampler.new(
      substitution_rate: 0.1,
      insertion_rate: 0.2,
      deletion_rate: 0.3,
      random: FixedRandom.new(0.3)
    )
    deletion_boundary = Wgsim::Mutate::MutationTypeSampler.new(
      substitution_rate: 0.1,
      insertion_rate: 0.2,
      deletion_rate: 0.3,
      random: FixedRandom.new(0.6)
    )

    substitution_boundary.sample.should eq Wgsim::MutationType::INSERT
    insertion_boundary.sample.should eq Wgsim::MutationType::DELETE
    deletion_boundary.sample.should eq Wgsim::MutationType::NOCHANGE
  end
end
