require "../mutation_type"

module Wgsim
  class MutationEvent
    property mutation_type : MutationType
    property reference_position : Int32
    property reference_allele : (Char | String)
    property alternate_allele : (Char | String)
    property sequence_name : String?

    def initialize(@mutation_type, @reference_position, @reference_allele, @alternate_allele, @sequence_name = nil)
    end

    def to_s : String
      String.build do |str|
        to_s(str)
      end
    end

    def to_s(io : IO)
      io << (sequence_name || "*")
      io << "\t"
      io << "#{reference_position}\t"
      io << "#{reference_allele}\t"
      io << "#{alternate_allele}\t"
      io << "#{mutation_type}"
    end
  end
end
