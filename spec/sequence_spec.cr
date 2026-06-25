require "./spec_helper"

describe Wgsim::Sequence::Core do
	it "re-samples insert size until it fits in the contig" do
		core = Wgsim::Sequence::Core.new(
			average_depth: 10.0,
			distance: 300,
			std_deviation: 100,
			size_left: 50,
			size_right: 50,
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
			distance: 10_000,
			std_deviation: 0,
			size_left: 50,
			size_right: 50,
			error_rate: 0.01,
			max_ambiguous_ratio: 0.05,
			seed: 1u64
		)

		core.random_insert_size(120).should eq(120)
	end
end
