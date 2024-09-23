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

    # FIXME This method should be moved to Sequence class because it is IO-related?
    def to_s : String
      sequence_str = String.new(sequence)
      String.build do |str|
        str << "@#{name}_#{position}_#{insert_size}:#{pair_index}/#{read_index + 1}" << "\n"
        str << sequence_str << "\n"
        str << "+" << "\n"
        str << ascii_quality.to_s * sequence_str.size << "\n"
      end
    end
  end
end
