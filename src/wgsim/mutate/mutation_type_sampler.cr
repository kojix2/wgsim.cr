require "../mutation_type"

module Wgsim
  class Mutate
    # Samples one mutation decision for a single non-ambiguous reference base.
    #
    # The intervals are laid out on [0, 1): substitution first, then insertion,
    # then deletion. Whatever probability mass remains means "no mutation".
    class MutationTypeSampler
      def initialize(
        @substitution_rate : Float64,
        @insertion_rate : Float64,
        @deletion_rate : Float64,
        @random,
      )
      end

      def sample : MutationType
        value = @random.rand
        # Example: if substitution=0.1, insertion=0.2, deletion=0.3,
        # then [0.0, 0.1) substitutes, [0.1, 0.3) inserts,
        # [0.3, 0.6) deletes, and the rest is unchanged.
        if value < @substitution_rate
          MutationType::SUBSTITUTE
        elsif value < (@substitution_rate + @insertion_rate)
          MutationType::INSERT
        elsif value < (@substitution_rate + @insertion_rate + @deletion_rate)
          MutationType::DELETE
        else
          MutationType::NOCHANGE
        end
      end
    end
  end
end
