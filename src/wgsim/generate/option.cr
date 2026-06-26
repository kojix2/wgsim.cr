module Wgsim
  class Generate
    class Option
      DEFAULT_CHROMOSOME_LENGTHS = [1000, 500]

      property chromosome_lengths : Array(Int32) = DEFAULT_CHROMOSOME_LENGTHS.dup
      property seed : UInt64?

      def summary
        <<-SUMMARY
        Chromosome lengths: #{chromosome_lengths.join(",")}
        Seed: #{seed.nil? ? "random" : seed}
        SUMMARY
      end

      def validate! : Nil
        if chromosome_lengths.empty?
          raise ArgumentError.new("At least one chromosome length is required")
        end

        chromosome_lengths.each do |length|
          raise ArgumentError.new("Chromosome length must be greater than 0") if length <= 0
        end
      end
    end
  end
end
