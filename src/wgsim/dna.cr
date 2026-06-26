module Wgsim
  module Dna
    BASE_A = 'A'.ord.to_u8
    BASE_C = 'C'.ord.to_u8
    BASE_G = 'G'.ord.to_u8
    BASE_T = 'T'.ord.to_u8
    BASE_N = 'N'.ord.to_u8

    LOWERCASE_BASE_A = 'a'.ord.to_u8
    LOWERCASE_BASE_C = 'c'.ord.to_u8
    LOWERCASE_BASE_G = 'g'.ord.to_u8
    LOWERCASE_BASE_T = 't'.ord.to_u8
    LOWERCASE_BASE_N = 'n'.ord.to_u8

    DNA_BASES           = StaticArray[BASE_A, BASE_C, BASE_G, BASE_T]
    SUBSTITUTIONS_FOR_A = StaticArray[BASE_C, BASE_G, BASE_T]
    SUBSTITUTIONS_FOR_C = StaticArray[BASE_A, BASE_G, BASE_T]
    SUBSTITUTIONS_FOR_G = StaticArray[BASE_A, BASE_C, BASE_T]
    SUBSTITUTIONS_FOR_T = StaticArray[BASE_A, BASE_C, BASE_G]

    COMPLEMENT_BASES = {
      BASE_A => BASE_T,
      BASE_C => BASE_G,
      BASE_G => BASE_C,
      BASE_T => BASE_A,
      BASE_N => BASE_N,
    }

    def normalize_base(base : UInt8) : UInt8
      case base
      when LOWERCASE_BASE_A
        BASE_A
      when LOWERCASE_BASE_C
        BASE_C
      when LOWERCASE_BASE_G
        BASE_G
      when LOWERCASE_BASE_T
        BASE_T
      when LOWERCASE_BASE_N
        BASE_N
      else
        base
      end
    end

    def normalize_sequence(sequence : Slice(UInt8)) : Slice(UInt8)
      sequence.map { |base| normalize_base(base) }
    end

    def perform_substitution(base : UInt8, i : Int) : UInt8
      base = normalize_base(base)
      case base
      when BASE_A
        SUBSTITUTIONS_FOR_A[i]
      when BASE_C
        SUBSTITUTIONS_FOR_C[i]
      when BASE_G
        SUBSTITUTIONS_FOR_G[i]
      when BASE_T
        SUBSTITUTIONS_FOR_T[i]
      else # N and others
        base
      end
    end

    def reverse_complement(sequence : Slice(UInt8)) : Slice(UInt8)
      sequence.map do |nucleotide|
        nucleotide = normalize_base(nucleotide)
        COMPLEMENT_BASES.fetch(nucleotide) { raise "Invalid nucleotide: #{nucleotide}" }
      end.reverse!
    end
  end
end
