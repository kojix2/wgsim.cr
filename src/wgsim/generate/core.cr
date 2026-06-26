require "randn"
require "../core_utils"

module Wgsim
  class Generate
    class Core
      include CoreUtils

      CHROMOSOME_NAME_PREFIX = "chr"

      def initialize(
        @chromosome_lengths : Array(Int32),
        @seed : UInt64? = nil,
      )
        # random number generator with seed
        seed = @seed
        @random = seed ? Rand.new(seed) : Rand.new
      end

      def generate_sequences(&)
        @chromosome_lengths.each_with_index do |length, idx|
          name = "#{CHROMOSOME_NAME_PREFIX}#{idx} size:#{length} seed:#{@seed || "random"}"
          sequence = Slice(UInt8).new(length) { DNA_BASES[@random.rand(DNA_BASES.size)] }
          yield({name, sequence})
        end
      end
    end
  end
end
