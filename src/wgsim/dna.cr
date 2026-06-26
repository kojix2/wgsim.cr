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

    IUPAC_AMBIGUOUS_BASES = StaticArray[
      'R'.ord.to_u8, 'Y'.ord.to_u8, 'S'.ord.to_u8, 'W'.ord.to_u8,
      'K'.ord.to_u8, 'M'.ord.to_u8, 'B'.ord.to_u8, 'D'.ord.to_u8,
      'H'.ord.to_u8, 'V'.ord.to_u8,
      'r'.ord.to_u8, 'y'.ord.to_u8, 's'.ord.to_u8, 'w'.ord.to_u8,
      'k'.ord.to_u8, 'm'.ord.to_u8, 'b'.ord.to_u8, 'd'.ord.to_u8,
      'h'.ord.to_u8, 'v'.ord.to_u8,
    ]

    NORMALIZE_BASES = begin
      table = StaticArray(UInt8, 256).new { |i| i.to_u8 }
      table[LOWERCASE_BASE_A] = BASE_A
      table[LOWERCASE_BASE_C] = BASE_C
      table[LOWERCASE_BASE_G] = BASE_G
      table[LOWERCASE_BASE_T] = BASE_T
      table[LOWERCASE_BASE_N] = BASE_N
      IUPAC_AMBIGUOUS_BASES.each { |base| table[base] = BASE_N }
      table
    end

    COMPLEMENT_BASES = {
      BASE_A => BASE_T,
      BASE_C => BASE_G,
      BASE_G => BASE_C,
      BASE_T => BASE_A,
      BASE_N => BASE_N,
    }

    def normalize_base(base : UInt8) : UInt8
      NORMALIZE_BASES[base]
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
