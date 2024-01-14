module Wgsim
  enum MutType : UInt8
    NOCHANGE   = 0
    SUBSTITUTE = 1
    DELETE     = 2
    INSERT     = 3
  end

  struct RefBase
    property nucleotide : UInt8
    property mutation_type : MutType
    property insertion : Slice(UInt8)?

    def initialize(@nucleotide, @mutation_type, @insertion = nil)
    end
  end
end
