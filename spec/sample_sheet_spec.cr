require "./spec_helper"

describe Wgsim do
  describe Wgsim::SampleSheet do
    it "loads a CSV file correctly" do
      samples = Wgsim::SampleSheet.load("spec/fixtures/samples.csv")
      samples.size.should eq(3)

      samples[0].name.should eq("cell1")
      samples[0].fraction.should eq(0.1)
      samples[0].fasta_file.should eq("cell1.fa")

      samples[1].name.should eq("cell2")
      samples[1].fraction.should eq(0.2)
      samples[1].fasta_file.should eq("cell2.fa")

      samples[2].name.should eq("cell3")
      samples[2].fraction.should eq(0.3)
      samples[2].fasta_file.should eq("cell3.fa")
    end

    it "loads a TSV file correctly" do
      samples = Wgsim::SampleSheet.load("spec/fixtures/samples.tsv")
      samples.size.should eq(3)

      samples[0].name.should eq("cell1")
      samples[0].fraction.should eq(0.1)
      samples[0].fasta_file.should eq("cell1.fa")

      samples[1].name.should eq("cell2")
      samples[1].fraction.should eq(0.2)
      samples[1].fasta_file.should eq("cell2.fa")

      samples[2].name.should eq("cell3")
      samples[2].fraction.should eq(0.3)
      samples[2].fasta_file.should eq("cell3.fa")
    end
  end
end
