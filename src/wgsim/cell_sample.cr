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
end
