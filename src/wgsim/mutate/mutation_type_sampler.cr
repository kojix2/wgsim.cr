require "../mutation_type"

module Wgsim
  class Mutate
    class MutationTypeSampler
      def initialize(
        @substitution_rate : Float64,
        @insertion_rate : Float64,
        @deletion_rate : Float64,
        @random : Rand,
      )
      end

      def sample : MutationType
        value = @random.rand
        if value <= @substitution_rate
          MutationType::SUBSTITUTE
        elsif value <= (@substitution_rate + @insertion_rate)
          MutationType::INSERT
        elsif value <= (@substitution_rate + @insertion_rate + @deletion_rate)
          MutationType::DELETE
        else
          MutationType::NOCHANGE
        end
      end
    end
  end
end
