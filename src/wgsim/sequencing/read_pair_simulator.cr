require "randn"
require "../dna"
require "../log"
require "./error_model"

module Wgsim
  class Sequencing
    class ReadPairSimulator
      include Dna
      delegate rand, randn, next_bool, to: @random

      PROGRESS_REPORT_COUNT       =     10
      MAX_INSERT_SIZE_RESAMPLINGS = 10_000

      property mean_insert_size : Int32
      property insert_size_std_dev : Int32
      property average_depth : Float64
      property read1_length : Int32
      property read2_length : Int32
      property error_rate : Float64
      property max_ambiguous_ratio : Float64

      def initialize(
        @average_depth,
        @mean_insert_size,
        @insert_size_std_dev,
        @read1_length,
        @read2_length,
        @error_rate,
        @max_ambiguous_ratio,
        @seed : UInt64? = nil,
      )
        seed = @seed
        @random = seed ? Rand.new(seed) : Rand.new
        @sequencing_error_model = ErrorModel.new(error_rate, @random)
      end

      def simulate_read_pairs(name, sequence, &)
        sequence = normalize_sequence(sequence)
        contig_length = sequence.size
        read_name = read_name_for(name)

        # Skip sequences (contigs) that are shorter than the minimum read length.
        min_read_length = Math.max(read1_length, read2_length)
        if contig_length < min_read_length
          Log.warn("skip sequence '#{name}' as it is shorter than #{min_read_length} bp")
          return
        end

        # depth per haploid
        n_pairs = (contig_length * average_depth / (read1_length + read2_length)).to_i

        # No pairs to generate
        return if n_pairs <= 0

        # progress report step (about 10 reports per contig, at least every pair)
        progress_step = (n_pairs / PROGRESS_REPORT_COUNT).to_i
        progress_step = 1 if progress_step <= 0

        # Currently, the sequence error rate is uniform across the entire sequence.
        # '2' if the error rate is [0.02].
        quality_char = @sequencing_error_model.quality_char
        read1_quality = Bytes.new(read1_length, quality_char.ord.to_u8)
        read2_quality = Bytes.new(read2_length, quality_char.ord.to_u8)

        pair_index = 0
        while pair_index < n_pairs
          # progress report
          if pair_index % progress_step == 0
            Log.info("#{name} #{pair_index}/#{n_pairs}")
          end
          current_pair_index = pair_index
          pair_index += 1

          # Insert size is the length of the DNA fragment excluding the adapters.
          # See image at https://www.biostars.org/p/95803/
          insert_size = sample_insert_size(contig_length)

          # The fragment start is the 0-based index of the first base of the fragment in the contig.
          fragment_start = sample_fragment_start(contig_length, insert_size)

          # Raise an error if the fragment coordinates are invalid. This should never happen.
          if fragment_start < 0 || fragment_start + insert_size > contig_length
            raise ArgumentError.new(
              "Invalid fragment start or insert size: " \
              "fragment_start=#{fragment_start}, insert_size=#{insert_size}, contig_length=#{contig_length}"
            )
          end

          # Select which end of the fragment is emitted as read 1.
          # 5'--->      3'
          # 3'     <--- 5'
          read1_starts_at_fragment_left = next_bool

          read1_sequence, read2_sequence = build_read_pair_sequences(sequence, fragment_start, insert_size, read1_starts_at_fragment_left)

          # Skip if the read contains too many ambiguous bases.
          next if read1_sequence.count(BASE_N).to_f / read1_sequence.size > max_ambiguous_ratio ||
                  read2_sequence.count(BASE_N).to_f / read2_sequence.size > max_ambiguous_ratio

          # generate sequence error
          read1_sequence = @sequencing_error_model.add_errors(read1_sequence)
          read2_sequence = @sequencing_error_model.add_errors(read2_sequence)

          yield(
            FastqRecord.new(read_name, current_pair_index, fragment_start, insert_size, 0, read1_sequence, read1_quality),
            FastqRecord.new(read_name, current_pair_index, fragment_start, insert_size, 1, read2_sequence, read2_quality)
          )
        end
      end

      def build_read_pair_sequences(contig_sequence, fragment_start, insert_size, read1_starts_at_fragment_left : Bool) : Tuple(Slice(UInt8), Slice(UInt8))
        # Ranges that use '...' to exclude the given end value.
        # (1...4).to_a     # => [1, 2, 3]
        if read1_starts_at_fragment_left
          read1 = contig_sequence[fragment_start...(fragment_start + read1_length)]
          read2 = reverse_complement(contig_sequence[(fragment_start + insert_size - read2_length)...(fragment_start + insert_size)])
        else
          read1 = reverse_complement(contig_sequence[(fragment_start + insert_size - read1_length)...(fragment_start + insert_size)])
          read2 = contig_sequence[fragment_start...(fragment_start + read2_length)]
        end

        {read1, read2}
      end

      def sample_insert_size(contig_length : Int32) : Int32
        min_insert_size = Math.max(read1_length, read2_length)
        if contig_length < min_insert_size
          raise ArgumentError.new("contig is shorter than minimum read length")
        end

        attempts = 0
        loop do
          insert_size = [randn(mean_insert_size, insert_size_std_dev).to_i, min_insert_size].max
          return insert_size if insert_size <= contig_length

          attempts += 1
          return contig_length if attempts >= MAX_INSERT_SIZE_RESAMPLINGS
        end
      end

      def sample_fragment_start(contig_length : Int, insert_size : Int) : Int32
        rand(contig_length - insert_size + 1)
      end

      private def read_name_for(name : String) : String
        space_index = name.index(' ')
        space_index ? name[0, space_index] : name
      end
    end
  end
end
