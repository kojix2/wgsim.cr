require "csv"
require "./cell_sample"

module Wgsim
  class SampleSheet
    SAMPLE_NAME_COLUMN   = 0
    CELL_FRACTION_COLUMN = 1
    FASTA_FILE_COLUMN    = 2
    TSV_FILE_EXTENSIONS  = {".txt", ".tsv"}
    TSV_COLUMN_SEPARATOR = '\t'
    CSV_COLUMN_SEPARATOR = ','

    def self.load(file : String) : Array(CellSample)
      sheet = self.new
      sheet.load(file)
    end

    def initialize
      @samples = [] of CellSample
    end

    def load(file : (String | Path)) : Array(CellSample)
      separator = column_separator_for_file(file)
      File.open(file) do |io|
        CSV.new(io, separator: separator).each do |row|
          sample_name = row[SAMPLE_NAME_COLUMN]
          cell_fraction = row[CELL_FRACTION_COLUMN].to_f
          fasta_file = row[FASTA_FILE_COLUMN]
          @samples << CellSample.new(sample_name, cell_fraction, fasta_file)
        end
      end
      @samples
    end

    private def column_separator_for_file(file : String) : Char
      if TSV_FILE_EXTENSIONS.includes?(File.extname(file))
        TSV_COLUMN_SEPARATOR
      else
        CSV_COLUMN_SEPARATOR
      end
    end
  end
end
