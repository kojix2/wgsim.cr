require "./spec_helper"

describe Wgsim::Mutate::MutationSimulator do
  it "formats mutated reference sequences with the requested line width" do
    simulator = Wgsim::Mutate::MutationSimulator.new(
      substitution_rate: 0.0,
      insertion_rate: 0.0,
      deletion_rate: 0.0,
      insertion_extension_probability: 0.0,
      deletion_extension_probability: 0.0,
      seed: 1
    )

    res, _elog = simulator.simulate_mutations("ACGTACGT".to_slice)

    res.format(width: 4).should eq("ACGT\nACGT\n")
  end

  it "can mutate a sequence" do
    simulator = Wgsim::Mutate::MutationSimulator.new(
      substitution_rate: 0.2,
      insertion_rate: 0.2,
      deletion_rate: 0.2,
      insertion_extension_probability: 0.5,
      deletion_extension_probability: 0.5,
      seed: 100
    )
    res, elog = simulator.simulate_mutations("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA".to_slice)

    first_event = elog.first
    first_event.sequence_name.should be_nil
    first_event.reference_position.should eq(1)
    first_event.reference_allele.should eq("A")
    first_event.alternate_allele.should eq('.')
    first_event.mutation_type.should eq(Wgsim::MutationType::DELETE)

    second_event = elog[1]
    second_event.sequence_name.should be_nil
    second_event.reference_position.should eq(3)
    second_event.reference_allele.should eq('A')
    second_event.alternate_allele.should eq('T')
    second_event.mutation_type.should eq(Wgsim::MutationType::SUBSTITUTE)

    last2_event = elog[-2]
    last2_event.sequence_name.should be_nil
    last2_event.reference_position.should eq(29)
    last2_event.reference_allele.should eq('A')
    last2_event.alternate_allele.should eq("ACGGG")
    last2_event.mutation_type.should eq(Wgsim::MutationType::INSERT)

    res.format.should eq("ATTAATAATAACCAACAAGACGGGAA")
  end

  it "does not carry over event_log across simulate_mutations calls" do
    simulator = Wgsim::Mutate::MutationSimulator.new(
      substitution_rate: 1.0,
      insertion_rate: 0.0,
      deletion_rate: 0.0,
      insertion_extension_probability: 0.0,
      deletion_extension_probability: 0.0,
      seed: 100
    )

    _, first_log = simulator.simulate_mutations("AAAA".to_slice)
    _, second_log = simulator.simulate_mutations("TTTT".to_slice)

    first_log.size.should eq(4)
    second_log.size.should eq(4)
  end

  it "records deletion event even when deletion reaches sequence end" do
    simulator = Wgsim::Mutate::MutationSimulator.new(
      substitution_rate: 0.0,
      insertion_rate: 0.0,
      deletion_rate: 1.0,
      insertion_extension_probability: 0.0,
      deletion_extension_probability: 1.0,
      seed: 1
    )

    _, elog = simulator.simulate_mutations("AAAA".to_slice)

    elog.size.should eq(1)
    elog.first.mutation_type.should eq(Wgsim::MutationType::DELETE)
    elog.first.reference_position.should eq(1)
    elog.first.reference_allele.should eq("AAAA")
    elog.first.alternate_allele.should eq('.')
  end

  it "normalizes lowercase bases before mutating" do
    simulator = Wgsim::Mutate::MutationSimulator.new(
      substitution_rate: 0.0,
      insertion_rate: 0.0,
      deletion_rate: 0.0,
      insertion_extension_probability: 0.0,
      deletion_extension_probability: 0.0,
      seed: 1
    )

    res, elog = simulator.simulate_mutations("acgtn".to_slice)

    elog.should be_empty
    res.format.should eq("ACGTN")
  end
end
