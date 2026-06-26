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
end
