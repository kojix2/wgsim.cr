module Wgsim
  struct RefBase
    property nucleotide : UInt8
    property mutation_type : MutType
    property insertion : Slice(UInt8)?

    def initialize(@nucleotide, @mutation_type, @insertion = nil)
    end
  end
end
