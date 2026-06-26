require "randn"
require "../dna"

module Wgsim
  class Generate
    class RandomReferenceGenerator
      include Dna

      CHROMOSOME_NAME_PREFIX = "chr"

      def initialize(
        @chromosome_lengths : Array(Int32),
        @seed : UInt64? = nil,
      )
        seed = @seed
        @random = seed ? Rand.new(seed) : Rand.new
      end

      def generate_sequences(&)
        @chromosome_lengths.each_with_index do |length, chromosome_index|
          name = "#{CHROMOSOME_NAME_PREFIX}#{chromosome_index} " \
                 "size:#{length} seed:#{@seed || "random"}"
          sequence = Slice(UInt8).new(length) { DNA_BASES[@random.rand(DNA_BASES.size)] }
          yield({name, sequence})
        end
      end
    end
  end
end
