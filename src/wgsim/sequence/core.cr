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
        @seed : UInt64? = nil,
      )
        seed = @seed
        @random = seed ? Rand.new(seed) : Rand.new
      end

      def run(name, sequence, &)
        sequence = normalize_sequence(sequence)
        contig_length = sequence.size
        read_name = read_name_for(name)

        # Skip sequences (contigs) that are shorter than the minimum read length.
        min_read_length = Math.max(size_left, size_right)
        if contig_length < min_read_length
          STDERR.puts "[wgsim] skip sequence '#{name}' as it is shorter than #{min_read_length} bp"
          return
        end

        # depth per haploid
        n_pairs = (contig_length * average_depth / (size_left + size_right)).to_i

        # No pairs to generate
        return if n_pairs <= 0

        # progress report step (about 10 reports per contig, at least every pair)
        progress_step = (n_pairs / 10).to_i
        progress_step = 1 if progress_step <= 0

        # Currently, the sequence error rate is uniform across the entire sequence.
        # '2' if the error rate is [0.02].
        ascii_quality = error_rate_to_quality_char(error_rate)

        pair_index = 0
        while pair_index < n_pairs
          # progress report
          if pair_index % progress_step == 0
            STDERR.puts "[wgsim] #{name} #{pair_index}/#{n_pairs}"
          end
          current_pair_index = pair_index
          pair_index += 1

          # Insert size is the length of the DNA fragment excluding the adapters.
          # See image at https://www.biostars.org/p/95803/
          insert_size = random_insert_size(contig_length)

          # Position is the 0-based index of the first base of the fragment in the contig.
          position = random_position(contig_length, insert_size)

          # Raise an error if the position is invalid. This should never happen.
          if position < 0 || position + insert_size > contig_length
            raise "Invalid position or insert size: " \
                  "position=#{position}, insert_size=#{insert_size}, contig_length=#{contig_length}"
          end

          # Flip or not
          # 5'--->      3'
          # 3'     <--- 5'
          # If flip is true, the read1 is on the right side of the fragment.
          flip = next_bool # Generate a random boolean value.

          read1_sequence, read2_sequence = generate_pair_sequence(sequence, position, insert_size, flip)

          # Skip if the read contains too many ambiguous bases.
          next if read1_sequence.count(78u8).to_f / read1_sequence.size > max_ambiguous_ratio ||
                  read2_sequence.count(78u8).to_f / read2_sequence.size > max_ambiguous_ratio

          # generate sequence error
          read1_sequence = generate_sequencing_error(read1_sequence)
          read2_sequence = generate_sequencing_error(read2_sequence)

          yield(
            FastqRecord.new(read_name, current_pair_index, position, insert_size, 0, read1_sequence, ascii_quality),
            FastqRecord.new(read_name, current_pair_index, position, insert_size, 1, read2_sequence, ascii_quality)
          )
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

      def error_rate_to_quality_char(e : Float64) : Char
        ((33 + (-10 * Math.log10(e))).round).to_u8.chr
      end

      def generate_sequencing_error(sequence : Slice(UInt8)) : Slice(UInt8)
        sequence.map do |base|
          if (base != 78u8) && (rand < error_rate)
            # Defined in core_utils.cr
            perform_substitution(base, rand(3))
          else
            base
          end
        end
      end

      def random_insert_size(contig_length : Int32) : Int32
        min_insert_size = Math.max(size_left, size_right)
        raise "contig is shorter than minimum read length" if contig_length < min_insert_size

        attempts = 0
        loop do
          insert_size = [randn(distance, std_deviation).to_i, min_insert_size].max
          return insert_size if insert_size <= contig_length

          attempts += 1
          return contig_length if attempts >= 10_000
        end
      end

      def random_position(contig_length : Int, insert_size : Int) : Int32
        rand(contig_length - insert_size + 1)
      end

      private def read_name_for(name : String) : String
        space_index = name.index(' ')
        space_index ? name[0, space_index] : name
      end
    end
  end
end
