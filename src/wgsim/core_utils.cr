module Wgsim
  module CoreUtils
    ACGT = StaticArray[65u8, 67u8, 71u8, 84u8]
    CGT  = StaticArray[67u8, 71u8, 84u8]
    AGT  = StaticArray[65u8, 71u8, 84u8]
    ACT  = StaticArray[65u8, 67u8, 84u8]
    ACG  = StaticArray[65u8, 67u8, 71u8]

    # def perform_substitution(base : UInt8) : UInt8
    #   i = rand(3)
    #   perform_substitution(base, i)
    # end

    def perform_substitution(base : UInt8, i : Int32) : UInt8
      case base
      when 65u8 # A
        CGT[i]
      when 67u8 # C
        AGT[i]
      when 71u8 # G
        ACT[i]
      when 84u8 # T
        ACG[i]
      else # N and others
        # 78u8
        base
      end
    end

    def reverse_complement(sequence : Slice(UInt8)) : Slice(UInt8)
      complements = {
        65u8 => 84u8, # A -> T
        67u8 => 71u8, # C -> G
        71u8 => 67u8, # G -> C
        84u8 => 65u8, # T -> A
        78u8 => 78u8, # N -> N
      }

      sequence.map do |b|
        complements.fetch(b) { raise "Invalid nucleotide: #{b}" }
      end.reverse!
    end
  end
end
