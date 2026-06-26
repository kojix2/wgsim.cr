require "./spec_helper"

class DnaTest
  include Wgsim::Dna
end

describe Wgsim::Dna do
  it "performs substitution" do
    dna = DnaTest.new
    dna.perform_substitution(base: 'A'.ord.to_u8, substitution_index: 0).should eq 'C'.ord
    dna.perform_substitution(base: 'A'.ord.to_u8, substitution_index: 1).should eq 'G'.ord
    dna.perform_substitution(base: 'A'.ord.to_u8, substitution_index: 2).should eq 'T'.ord
    dna.perform_substitution(base: 'C'.ord.to_u8, substitution_index: 0).should eq 'A'.ord
    dna.perform_substitution(base: 'C'.ord.to_u8, substitution_index: 1).should eq 'G'.ord
    dna.perform_substitution(base: 'C'.ord.to_u8, substitution_index: 2).should eq 'T'.ord
    dna.perform_substitution(base: 'G'.ord.to_u8, substitution_index: 0).should eq 'A'.ord
    dna.perform_substitution(base: 'G'.ord.to_u8, substitution_index: 1).should eq 'C'.ord
    dna.perform_substitution(base: 'G'.ord.to_u8, substitution_index: 2).should eq 'T'.ord
    dna.perform_substitution(base: 'T'.ord.to_u8, substitution_index: 0).should eq 'A'.ord
    dna.perform_substitution(base: 'T'.ord.to_u8, substitution_index: 1).should eq 'C'.ord
    dna.perform_substitution(base: 'T'.ord.to_u8, substitution_index: 2).should eq 'G'.ord
    dna.perform_substitution(base: 'N'.ord.to_u8, substitution_index: 0).should eq 'N'.ord
    dna.perform_substitution(base: 'N'.ord.to_u8, substitution_index: 1).should eq 'N'.ord
    dna.perform_substitution(base: 'N'.ord.to_u8, substitution_index: 2).should eq 'N'.ord
  end

  it "normalizes IUPAC ambiguous bases to N" do
    dna = DnaTest.new

    dna.normalize_sequence(
      sequence: "RYSWKMBDHVryswkmbdhv".to_slice
    ).should eq "NNNNNNNNNNNNNNNNNNNN".to_slice
    dna.perform_substitution(base: 'R'.ord.to_u8, substitution_index: 0).should eq 'N'.ord
  end

  it "reverse complements a DNA sequence" do
    dna = DnaTest.new
    dna.reverse_complement("ACGT".to_slice).should eq "ACGT".to_slice
    dna.reverse_complement("ACGTN".to_slice).should eq "NACGT".to_slice
    dna.reverse_complement("ACGTACGT".to_slice).should eq "ACGTACGT".to_slice
    dna.reverse_complement("ACGTACGTN".to_slice).should eq "NACGTACGT".to_slice
    dna.reverse_complement("acgtn".to_slice).should eq "NACGT".to_slice
    dna.reverse_complement(
      sequence: "ACGTRYKWSMBDHVacgtrykwsmbdhv".to_slice
    ).should eq "NNNNNNNNNNACGTNNNNNNNNNNACGT".to_slice
  end
end
