require "./spec_helper"

describe Wgsim::Sequencing::ReadPairSimulator do
  it "writes records compatibly with the fastx FASTQ writer" do
    record = Wgsim::Sequencing::FastqRecord.new(
      read_name: "chr1",
      pair_index: 2,
      fragment_start: 10,
      insert_size: 50,
      mate_index: 1,
      read_sequence: "ACGT".to_slice,
      quality_sequence: "2222".to_slice
    )
    io = IO::Memory.new

    writer = Fastx::Fastq::Writer.new(io)
    writer.write(record.identifier, record.read_sequence, record.quality_sequence)
    writer.close

    String.new(io.to_slice).should eq(record.to_s)
  end

  it "re-samples insert size until it fits in the contig" do
    simulator = Wgsim::Sequencing::ReadPairSimulator.new(
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
      insert_size = simulator.sample_insert_size(contig_length: 120)
      insert_size.should be >= 50
      insert_size.should be <= 120
    end
  end

  it "falls back to contig length when distribution cannot fit" do
    simulator = Wgsim::Sequencing::ReadPairSimulator.new(
      average_depth: 10.0,
      mean_insert_size: 10_000,
      insert_size_std_dev: 0,
      read1_length: 50,
      read2_length: 50,
      error_rate: 0.01,
      max_ambiguous_ratio: 0.05,
      seed: 1u64
    )

    simulator.sample_insert_size(contig_length: 120).should eq(120)
  end

  it "discards reads above the ambiguous-base ratio without looping forever" do
    simulator = Wgsim::Sequencing::ReadPairSimulator.new(
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
    simulator.simulate_read_pairs(
      sequence_name: "ambiguous",
      sequence: ("NNAAAAAAAA" * 20).to_slice
    ) do
      pairs += 1
    end

    pairs.should eq(0)
  end

  it "normalizes lowercase bases before generating reads" do
    simulator = Wgsim::Sequencing::ReadPairSimulator.new(
      average_depth: 1.0,
      mean_insert_size: 8,
      insert_size_std_dev: 0,
      read1_length: 4,
      read2_length: 4,
      error_rate: 0.01,
      max_ambiguous_ratio: 1.0,
      seed: 1u64
    )

    records = [] of Wgsim::Sequencing::FastqRecord
    simulator.simulate_read_pairs(
      sequence_name: "lowercase",
      sequence: "acgtacgt".to_slice
    ) do |record1, record2|
      records << record1
      records << record2
    end

    records.map { |record| String.new(record.read_sequence) }.should eq(["ACGT", "ACGT"])
  end
end
