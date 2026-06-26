require "./spec_helper"

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
    sampler = Wgsim::Mutate::MutationTypeSampler.new(
      substitution_rate: 0.125,
      insertion_rate: 0.25,
      deletion_rate: 0.5,
      random: Rand.new(1u64)
    )

    sampler.sample(value: 0.125).should eq Wgsim::MutationType::INSERT
    sampler.sample(value: 0.375).should eq Wgsim::MutationType::DELETE
    sampler.sample(value: 0.875).should eq Wgsim::MutationType::NOCHANGE
  end
end
