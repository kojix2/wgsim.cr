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

      def validate! : Nil
        raise ArgumentError.new("At least one chromosome length is required") if chromosome_length.empty?

        chromosome_length.each do |length|
          raise ArgumentError.new("Chromosome length must be greater than 0") if length <= 0
        end
      end
    end
  end
end
