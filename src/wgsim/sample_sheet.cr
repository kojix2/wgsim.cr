require "csv"

module Wgsim
  class CellSample
    getter name : String
    getter fraction : Float64
    getter fasta_file : String

    def initialize(name : String, fraction : Float64, fasta_file : String)
      @name = name
      @fraction = fraction
      @fasta_file = fasta_file
    end
  end

  class SampleSheet
    def self.load(file : String) : Array(CellSample)
      sheet = self.new
      sheet.load(file)
    end

    def initialize
      @samples = [] of CellSample
    end

    def load(file : (String | Path)) : Array(CellSample)
      separator = determine_separator(file)
      File.open(file) do |f|
        CSV.new(f, separator: separator).each do |row|
          name, fraction, fasta_file = row[0], row[1].to_f, row[2]
          @samples << CellSample.new(name, fraction, fasta_file)
        end
      end
      @samples
    end

    private def determine_separator(file : String) : Char
      case File.extname(file)
      when ".txt", ".tsv"
        '\t'
      else
        ','
      end
    end
  end
end
