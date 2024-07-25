module Wgsim
  class Generate
    class Option
      property chromosome_length : Array(Int32) = [1000, 500]
      property seed : UInt64?

      def summary
        <<-SUMMARY
        Chromosome length: #{chromosome_length.join(",")}
        Seed: #{seed.nil? ? "random" : seed}
        SUMMARY
      end
    end
  end
end
