require "./spec_helper"

describe Wgsim::Sequence::SequencingErrorModel do
  it "converts an error rate to a FASTQ quality character" do
    random = Rand.new(1u64)
    model = Wgsim::Sequence::SequencingErrorModel.new(0.02, random)

    model.quality_char.should eq '2'
  end

  it "does not mutate ambiguous bases" do
    random = Rand.new(1u64)
    model = Wgsim::Sequence::SequencingErrorModel.new(1.0, random)

    model.add_errors("NNNN".to_slice).should eq "NNNN".to_slice
  end
end
