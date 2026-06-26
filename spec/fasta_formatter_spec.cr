require "./spec_helper"

describe Wgsim::FastaFormatter do
  it "wraps a sequence at the requested line width" do
    Wgsim::FastaFormatter.wrap("ACGTACGT".to_slice, width: 4).should eq "ACGT\nACGT\n"
  end
end
