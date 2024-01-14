require "./spec_helper"

describe Wgsim::ReadFasta do
  it "should read a fasta file" do
    names = [] of String
    sequences = [] of String
    Wgsim::ReadFasta.each_contig("spec/fixtures/moo.fa") do |name, sequence|
      names << name
      sequences << sequence.to_s
    end
    names[0].should eq "chr1 1"
    names[1].should eq "chr2 2"
    sequences[0].size.should eq 1000
    sequences[0].starts_with?("CGCAAC").should be_true
    sequences[0].ends_with?("AACATCC").should be_true
    sequences[1].size.should eq 900
    sequences[1].starts_with?("TGAGAGC").should be_true
    sequences[1].ends_with?("CGTTTGC").should be_true
  end

  it "should read a fa.gz file" do
    names = [] of String
    sequences = [] of String
    Wgsim::ReadFasta.each_contig("spec/fixtures/moo.fa.gz") do |name, sequence|
      names << name
      sequences << sequence.to_s
    end
    names[0].should eq "chr1 1"
    names[1].should eq "chr2 2"
    sequences[0].size.should eq 1000
    sequences[0].starts_with?("CGCAAC").should be_true
    sequences[0].ends_with?("AACATCC").should be_true
    sequences[1].size.should eq 900
    sequences[1].starts_with?("TGAGAGC").should be_true
    sequences[1].ends_with?("CGTTTGC").should be_true
  end
end
