module Wgsim
  module FastaFormatter
    DEFAULT_LINE_WIDTH = 80

    def self.wrap(sequence : Slice(UInt8), width : Int = DEFAULT_LINE_WIDTH) : String
      wrap(IO::Memory.new(sequence), width: width)
    end

    def self.wrap(sequence : IO::Memory, width : Int = DEFAULT_LINE_WIDTH) : String
      sequence.to_s.gsub(/(.{#{width}})/, "\\1\n")
    end
  end
end
