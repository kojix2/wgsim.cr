require "randn"
require "../core_utils"

module Wgsim
  class Generate
    class Core
      include CoreUtils

      def initialize(
        @chromosome_length : Array(Int32),
        @seed : UInt64? = nil,
      )
        # random number generator with seed
        @random = \
           if @seed
             Rand.new(@seed.not_nil!)
           else
             Rand.new
           end
        @chr_name = "chr"
      end

      def generate_sequence(&)
        @chromosome_length.each_with_index do |length, idx|
          name = "#{@chr_name}#{idx} size:#{length} seed:#{@seed || "random"}"
          sequence = Slice(UInt8).new(length) { ACGT[@random.rand(4)] }
          yield({name, sequence})
        end
      end
    end
  end
end
