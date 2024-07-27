require "../mut_type"

module Wgsim
  class EventRecord
    property mut_type : MutType
    property position : Int32
    property ref_seq : (Char | String)
    property alt_seq : (Char | String)
    property name : String?

    def initialize(@mut_type, @position, @ref_seq, @alt_seq, @name = nil)
    end

    def to_s : String
      String.build do |str|
        to_s(str)
      end
    end

    def to_s(io : IO)
      io << (name || "*")
      io << "\t"
      io << "#{position}\t"
      io << "#{ref_seq}\t"
      io << "#{alt_seq}\t"
      io << "#{mut_type}"
    end
  end
end
