require "./spec_helper"

class CoreUtilsTest
  include Wgsim::CoreUtils
end

describe Wgsim::CoreUtils do
  it "it perform substitution" do
    core = CoreUtilsTest.new
    core.perform_substitution('A'.ord.to_u8, 0).should eq 'C'.ord
    core.perform_substitution('A'.ord.to_u8, 1).should eq 'G'.ord
    core.perform_substitution('A'.ord.to_u8, 2).should eq 'T'.ord
    core.perform_substitution('C'.ord.to_u8, 0).should eq 'A'.ord
    core.perform_substitution('C'.ord.to_u8, 1).should eq 'G'.ord
    core.perform_substitution('C'.ord.to_u8, 2).should eq 'T'.ord
    core.perform_substitution('G'.ord.to_u8, 0).should eq 'A'.ord
    core.perform_substitution('G'.ord.to_u8, 1).should eq 'C'.ord
    core.perform_substitution('G'.ord.to_u8, 2).should eq 'T'.ord
    core.perform_substitution('T'.ord.to_u8, 0).should eq 'A'.ord
    core.perform_substitution('T'.ord.to_u8, 1).should eq 'C'.ord
    core.perform_substitution('T'.ord.to_u8, 2).should eq 'G'.ord
    core.perform_substitution('N'.ord.to_u8, 0).should eq 'N'.ord
    core.perform_substitution('N'.ord.to_u8, 1).should eq 'N'.ord
    core.perform_substitution('N'.ord.to_u8, 2).should eq 'N'.ord
  end

  it "reverse complement" do
    core = CoreUtilsTest.new
    core.reverse_complement("ACGT".to_slice).should eq "ACGT".to_slice
    core.reverse_complement("ACGTN".to_slice).should eq "NACGT".to_slice
    core.reverse_complement("ACGTACGT".to_slice).should eq "ACGTACGT".to_slice
    core.reverse_complement("ACGTACGTN".to_slice).should eq "NACGTACGT".to_slice
  end
end
