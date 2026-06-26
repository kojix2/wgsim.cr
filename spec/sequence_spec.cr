require "./spec_helper"

describe Wgsim::Sequence::Core do
  it "re-samples insert size until it fits in the contig" do
    core = Wgsim::Sequence::Core.new(
      average_depth: 10.0,
      mean_insert_size: 300,
      insert_size_std_dev: 100,
      read1_length: 50,
      read2_length: 50,
      error_rate: 0.01,
      max_ambiguous_ratio: 0.05,
      seed: 123u64
    )

    100.times do
      insert_size = core.random_insert_size(120)
      insert_size.should be >= 50
      insert_size.should be <= 120
    end
  end

  it "falls back to contig length when distribution cannot fit" do
    core = Wgsim::Sequence::Core.new(
      average_depth: 10.0,
      mean_insert_size: 10_000,
      insert_size_std_dev: 0,
      read1_length: 50,
      read2_length: 50,
      error_rate: 0.01,
      max_ambiguous_ratio: 0.05,
      seed: 1u64
    )

    core.random_insert_size(120).should eq(120)
  end

  it "discards reads above the ambiguous-base ratio without looping forever" do
    core = Wgsim::Sequence::Core.new(
      average_depth: 10.0,
      mean_insert_size: 10,
      insert_size_std_dev: 0,
      read1_length: 10,
      read2_length: 10,
      error_rate: 0.01,
      max_ambiguous_ratio: 0.05,
      seed: 1u64
    )

    pairs = 0
    core.run("ambiguous", ("NNAAAAAAAA" * 20).to_slice) do
      pairs += 1
    end

    pairs.should eq(0)
  end

  it "normalizes lowercase bases before generating reads" do
    core = Wgsim::Sequence::Core.new(
      average_depth: 1.0,
      mean_insert_size: 8,
      insert_size_std_dev: 0,
      read1_length: 4,
      read2_length: 4,
      error_rate: 0.01,
      max_ambiguous_ratio: 1.0,
      seed: 1u64
    )

    records = [] of Wgsim::FastqRecord
    core.run("lowercase", "acgtacgt".to_slice) do |record1, record2|
      records << record1
      records << record2
    end

    records.map { |record| String.new(record.read_sequence) }.should eq(["ACGT", "ACGT"])
  end
end
