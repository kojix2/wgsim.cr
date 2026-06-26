require "./spec_helper"

class DnaTest
  include Wgsim::Dna
end

describe Wgsim::Dna do
  it "performs substitution" do
    dna = DnaTest.new
    dna.perform_substitution('A'.ord.to_u8, 0).should eq 'C'.ord
    dna.perform_substitution('A'.ord.to_u8, 1).should eq 'G'.ord
    dna.perform_substitution('A'.ord.to_u8, 2).should eq 'T'.ord
    dna.perform_substitution('C'.ord.to_u8, 0).should eq 'A'.ord
    dna.perform_substitution('C'.ord.to_u8, 1).should eq 'G'.ord
    dna.perform_substitution('C'.ord.to_u8, 2).should eq 'T'.ord
    dna.perform_substitution('G'.ord.to_u8, 0).should eq 'A'.ord
    dna.perform_substitution('G'.ord.to_u8, 1).should eq 'C'.ord
    dna.perform_substitution('G'.ord.to_u8, 2).should eq 'T'.ord
    dna.perform_substitution('T'.ord.to_u8, 0).should eq 'A'.ord
    dna.perform_substitution('T'.ord.to_u8, 1).should eq 'C'.ord
    dna.perform_substitution('T'.ord.to_u8, 2).should eq 'G'.ord
    dna.perform_substitution('N'.ord.to_u8, 0).should eq 'N'.ord
    dna.perform_substitution('N'.ord.to_u8, 1).should eq 'N'.ord
    dna.perform_substitution('N'.ord.to_u8, 2).should eq 'N'.ord
  end

  it "reverse complements a DNA sequence" do
    dna = DnaTest.new
    dna.reverse_complement("ACGT".to_slice).should eq "ACGT".to_slice
    dna.reverse_complement("ACGTN".to_slice).should eq "NACGT".to_slice
    dna.reverse_complement("ACGTACGT".to_slice).should eq "ACGTACGT".to_slice
    dna.reverse_complement("ACGTACGTN".to_slice).should eq "NACGTACGT".to_slice
    dna.reverse_complement("acgtn".to_slice).should eq "NACGT".to_slice
  end
end
