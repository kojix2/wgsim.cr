module Wgsim
  class Sequencing
    struct FastqRecord
      property read_name : String
      property pair_index : Int32
      property fragment_start : Int32
      property insert_size : Int32
      property mate_index : Int32
      property read_sequence : Slice(UInt8)
      property quality_sequence : Slice(UInt8)

      def initialize(
        @read_name,
        @pair_index,
        @fragment_start,
        @insert_size,
        @mate_index,
        @read_sequence,
        @quality_sequence,
      )
      end

      def identifier : String
        "#{read_name}_#{fragment_start}_#{insert_size}:#{pair_index}/#{mate_index + 1}"
      end

      def to_s : String
        String.build do |str|
          to_s(str)
        end
      end

      def to_s(io : IO)
        io << '@' << identifier << '\n'
        io.write(read_sequence)
        io << '\n'
        io << '+' << '\n'
        io.write(quality_sequence)
        io << '\n'
      end
    end
  end
end
