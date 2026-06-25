module Wgsim
  struct FastqRecord
    property name : String
    property pair_index : Int32
    property position : Int32
    property insert_size : Int32
    property read_index : Int32
    property sequence : Slice(UInt8)
    property ascii_quality : Char

    def initialize(@name, @pair_index, @position, @insert_size, @read_index, @sequence, @ascii_quality)
    end

    # NOTE: This method may be moved to Sequence class because it is IO-related.
    def to_s : String
      String.build do |str|
        to_s(str)
      end
    end

    def to_s(io : IO)
      io << '@' << name << '_' << position << '_' << insert_size << ':' << pair_index << '/' << (read_index + 1) << '\n'
      io.write(sequence)
      io << '\n'
      io << '+' << '\n'
      sequence.size.times do
        io << ascii_quality
      end
      io << '\n'
    end
  end
end
