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

    mutated_sequence, _mutation_events = simulator.simulate_mutations("ACGTACGT".to_slice)

    mutated_sequence.format(width: 4).should eq("ACGT\nACGT\n")
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
    mutated_sequence, mutation_events = simulator.simulate_mutations("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA".to_slice)

    first_event = mutation_events.first
    first_event.sequence_name.should be_nil
    first_event.reference_position.should eq(1)
    first_event.reference_allele.should eq("A")
    first_event.alternate_allele.should eq('.')
    first_event.mutation_type.should eq(Wgsim::MutationType::DELETE)

    second_event = mutation_events[1]
    second_event.sequence_name.should be_nil
    second_event.reference_position.should eq(3)
    second_event.reference_allele.should eq('A')
    second_event.alternate_allele.should eq('T')
    second_event.mutation_type.should eq(Wgsim::MutationType::SUBSTITUTE)

    penultimate_event = mutation_events[-2]
    penultimate_event.sequence_name.should be_nil
    penultimate_event.reference_position.should eq(29)
    penultimate_event.reference_allele.should eq('A')
    penultimate_event.alternate_allele.should eq("ACGGG")
    penultimate_event.mutation_type.should eq(Wgsim::MutationType::INSERT)

    mutated_sequence.format.should eq("ATTAATAATAACCAACAAGACGGGAA")
  end

  it "does not carry over mutation events across simulate_mutations calls" do
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

    _, mutation_events = simulator.simulate_mutations("AAAA".to_slice)

    mutation_events.size.should eq(1)
    mutation_events.first.mutation_type.should eq(Wgsim::MutationType::DELETE)
    mutation_events.first.reference_position.should eq(1)
    mutation_events.first.reference_allele.should eq("AAAA")
    mutation_events.first.alternate_allele.should eq('.')
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

    mutated_sequence, mutation_events = simulator.simulate_mutations("acgtn".to_slice)

    mutation_events.should be_empty
    mutated_sequence.format.should eq("ACGTN")
  end
end
