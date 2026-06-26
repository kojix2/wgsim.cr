module Wgsim
  class CellSample
    getter name : String
    getter cell_fraction : Float64
    getter fasta_file : String

    def initialize(name : String, cell_fraction : Float64, fasta_file : String)
      @name = name
      @cell_fraction = cell_fraction
      @fasta_file = fasta_file
    end

    def fraction : Float64
      cell_fraction
    end
  end
end
