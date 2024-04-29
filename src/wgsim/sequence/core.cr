require "randn"
require "../core_utils"

module Wgsim
  class Sequence
    class Core
      include CoreUtils
      delegate rand, randn, next_bool, to: @random

      property distance : Int32
      property std_deviation : Int32
      property average_depth : Float64
      property size_left : Int32
      property size_right : Int32
      property error_rate : Float64
      property max_ambiguous_ratio : Float64

      def initialize(
        @average_depth,
        @distance,
        @std_deviation,
        @size_left,
        @size_right,
        @error_rate,
        @max_ambiguous_ratio,
        @seed : UInt64? = nil
      )
        @random = \
           if @seed
             Rand.new(@seed.not_nil!)
           else
             Rand.new
           end
      end

      def run(name, sequence)
        contig_length = sequence.size

        # # Skip sequences(contigs) that are shorter than the minimum length.
        # if contig_length < (min_len = distance + 3 * std_deviation)
        #   STDERR.puts "[wgsim] skip sequence '#{name}' as it is shorter than #{min_len} bp"
        #   next
        # end

        # depth per haploid
        n_pairs = (contig_length * average_depth / (size_left + size_right)).to_i

        pair_index = 0
        while pair_index < n_pairs
          # progress report
          if pair_index % 10**(Math.log10(n_pairs).to_i - 1) == 0
            puts "[wgsim] #{name} #{pair_index}/#{n_pairs}"
          end

          # Insert size is the length of the DNA fragment excluding the adapters.
          # See image at https://www.biostars.org/p/95803/
          insert_size = random_insert_size

          # Position is the 0-based index of the first base of the fragment in the contig.
          position = random_position(contig_length, insert_size)

          # Raise an error if the position is invalid.
          # This should never happen.
          position < 0 || position > contig_length || position + insert_size - 1 < contig_length ||
            raise "Invalid position or insert size: " \
                  "position=#{position}, insert_size=#{insert_size}, contig_length=#{contig_length}"

          # Flip or not
          # 5'--->      3'
          # 3'     <--- 5'
          # If flip is true, the read1 is on the right side of the fragment.
          flip = next_bool # Generate a random boolean value.

          read1_sequence, read2_sequence = generate_pair_sequence(sequence, position, insert_size, flip)

          # Skip if the read contains too many ambiguous bases.
          next if read1_sequence.count('N') / read1_sequence.size > max_ambiguous_ratio ||
                  read2_sequence.count('N') / read2_sequence.size > max_ambiguous_ratio

          # generate sequence error
          read1_sequence = generate_sequencing_error(read1_sequence)
          read2_sequence = generate_sequencing_error(read2_sequence)

          yield(
            fasta_record(name.split[0], pair_index, position, insert_size, 0, read1_sequence),
            fasta_record(name.split[0], pair_index, position, insert_size, 1, read2_sequence)
          )

          pair_index += 1
        end
      end

      def generate_pair_sequence(target_seq, position, insert_size, flip : Bool) : Tuple(Slice(UInt8), Slice(UInt8))
        # Ranges that use '...' to exclude the given end value.
        # (1...4).to_a     # => [1, 2, 3]
        if flip
          read1 = target_seq[position...(position + size_left)]
          read2 = reverse_complement(target_seq[(position + insert_size - size_right)...(position + insert_size)])
        else
          read1 = reverse_complement(target_seq[(position + insert_size - size_left)...(position + insert_size)])
          read2 = target_seq[position...(position + size_right)]
        end

        {read1, read2}
      end

      # FIXME This method should be moved to Sequence class because it is IO-related?

      def fasta_record(name, pair_index, position, insert_size, read_index, sequence : Slice(UInt8)) : String
        sequence = String.new(sequence)
        String.build do |str|
          str << ">#{name}_#{position}_#{insert_size}:#{pair_index}/#{read_index + 1}" << "\n"
          str << sequence << "\n"
          str << "+" << "\n"
          str << "2" * [size_left, size_right][read_index] << "\n"
        end
      end

      def generate_sequencing_error(sequence : Slice(UInt8)) : Slice(UInt8)
        sequence.map do |base|
          if (base != 78u8) && (rand < error_rate)
            # Defined in core_utils.cr
            perform_substitution(base)
          else
            base
          end
        end
      end

      def random_insert_size
        [randn(distance, std_deviation).to_i, size_left, size_right].max
      end

      def random_position(contig_length : Int, insert_size : Int)
        rand(contig_length - insert_size + 1)
      end
    end
  end
end
