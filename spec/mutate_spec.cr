require "./spec_helper"

describe Wgsim::Mutate::Core do
  it "can mutate a sequence" do
    log = IO::Memory.new
    core = Wgsim::Mutate::Core.new(
      substitution_rate: 0.2,
      insertion_rate: 0.2,
      deletion_rate: 0.2,
      insertion_extension_probability: 0.5,
      deletion_extension_probability: 0.5,
      seed: 100,
      outlog: log
    )
    res, _ = core.simulate_mutations("tanuki", "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA".to_slice)
    res.format.should eq("ATTAATAATAACCAACAAGACGGGAA")
  end
end
