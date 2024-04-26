module Wgsim
  class Mutate
    class Option
      property reference : Path?
      property ploidy : UInt8 = 2
      property seed : UInt64?
      property substitution_rate : Float64 = 0.001
      property insertion_rate : Float64 = 0.0001
      property deletion_rate : Float64 = 0.0001
      property insertion_extension_probability : Float64 = 0.3
      property deletion_extension_probability : Float64 = 0.3

      def summary
        <<-SUMMARY
        Reference: #{reference}
        Ploidy: #{ploidy}
        Seed: #{seed.nil? ? "random" : seed}
        Substitution rate: #{substitution_rate}
        Insertion    rate: #{insertion_rate}
        Deletion     rate: #{deletion_rate}
        Insertion extension probability: #{insertion_extension_probability}
        Deletion  extension probability: #{deletion_extension_probability}
        SUMMARY
      end
    end
  end
end
