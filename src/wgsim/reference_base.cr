module Wgsim
  struct ReferenceBase
    property nucleotide : UInt8
    property mutation_type : MutationType
    property insertion : Slice(UInt8)?

    def initialize(@nucleotide, @mutation_type, @insertion = nil)
    end
  end
end
