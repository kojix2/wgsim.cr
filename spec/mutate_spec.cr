require "./spec_helper"

describe Wgsim::Mutate::Core do
  it "can mutate a sequence" do
    core = Wgsim::Mutate::Core.new(
      substitution_rate: 0.2,
      insertion_rate: 0.2,
      deletion_rate: 0.2,
      insertion_extension_probability: 0.5,
      deletion_extension_probability: 0.5,
      seed: 100
    )
    res, elog = core.simulate_mutations("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA".to_slice)

    first_event = elog.first
    first_event.name.should be_nil
    first_event.position.should eq(1)
    first_event.ref_seq.should eq("A")
    first_event.alt_seq.should eq('.')
    first_event.mut_type.should eq(Wgsim::MutType::DELETE)

    second_event = elog[1]
    second_event.name.should be_nil
    second_event.position.should eq(3)
    second_event.ref_seq.should eq('A')
    second_event.alt_seq.should eq('T')
    second_event.mut_type.should eq(Wgsim::MutType::SUBSTITUTE)

    last2_event = elog[-2]
    last2_event.name.should be_nil
    last2_event.position.should eq(29)
    last2_event.ref_seq.should eq('A')
    last2_event.alt_seq.should eq("ACGGG")
    last2_event.mut_type.should eq(Wgsim::MutType::INSERT)

    res.format.should eq("ATTAATAATAACCAACAAGACGGGAA")
  end
end
