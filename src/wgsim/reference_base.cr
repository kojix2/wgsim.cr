module Wgsim
  # One emitted base in the mutated reference sequence.
  #
  # Insertions are attached to the preceding reference nucleotide so the
  # original coordinate system stays visible while building the output FASTA.
  struct ReferenceBase
    property nucleotide : UInt8
    property mutation_type : MutationType
    property insertion : Slice(UInt8)?

    def initialize(@nucleotide, @mutation_type, @insertion = nil)
    end
  end
end
