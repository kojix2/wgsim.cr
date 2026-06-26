require "randn"
require "../dna"
require "../console"
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
        @sequencing_error_model = ErrorModel.new(
          error_rate: error_rate,
          random: @random
        )
      end

      def simulate_read_pairs(sequence_name, sequence, &)
        sequence = normalize_sequence(sequence)
        contig_length = sequence.size
        read_name = read_name_for(sequence_name)

        minimum_read_length = minimum_read_length_for_pair
        if contig_length < minimum_read_length
          Console.warn(
            "skip sequence '#{sequence_name}' " \
            "as it is shorter than #{minimum_read_length} bp"
          )
          return
        end

        read_pair_count = expected_read_pair_count(contig_length: contig_length)

        return if read_pair_count <= 0

        progress_step = progress_step_for(read_pair_count: read_pair_count)

        # Currently, the sequencing error rate is uniform across each read.
        # '2' if the error rate is [0.02].
        quality_char = @sequencing_error_model.quality_char
        read1_quality = Bytes.new(read1_length, quality_char.ord.to_u8)
        read2_quality = Bytes.new(read2_length, quality_char.ord.to_u8)

        pair_index = 0
        while pair_index < read_pair_count
          if pair_index % progress_step == 0
            Console.info("#{sequence_name} #{pair_index}/#{read_pair_count}")
          end
          current_pair_index = pair_index
          pair_index += 1

          insert_size = sample_insert_size(contig_length: contig_length)

          # The fragment start is the 0-based index of the first base of the fragment in the contig.
          fragment_start = sample_fragment_start(
            contig_length: contig_length,
            insert_size: insert_size
          )

          # Raise an error if the fragment coordinates are invalid. This should never happen.
          if fragment_start < 0 || fragment_start + insert_size > contig_length
            raise ArgumentError.new(
              "Invalid fragment start or insert size: " \
              "fragment_start=#{fragment_start}, " \
              "insert_size=#{insert_size}, " \
              "contig_length=#{contig_length}"
            )
          end

          # Select which end of the fragment is emitted as read 1.
          # 5'--->      3'
          # 3'     <--- 5'
          read1_starts_at_fragment_left = next_bool

          read1_sequence, read2_sequence = build_read_pair_sequences(
            contig_sequence: sequence,
            fragment_start: fragment_start,
            insert_size: insert_size,
            read1_starts_at_fragment_left: read1_starts_at_fragment_left
          )

          # Skip if the read contains too many ambiguous bases.
          next if too_many_ambiguous_bases?(read1_sequence) ||
                  too_many_ambiguous_bases?(read2_sequence)

          # Add synthetic sequencing errors after read extraction. The source
          # reference remains unchanged; only observed reads contain errors.
          read1_sequence = @sequencing_error_model.add_errors(read1_sequence)
          read2_sequence = @sequencing_error_model.add_errors(read2_sequence)

          yield(
            FastqRecord.new(
              read_name: read_name,
              pair_index: current_pair_index,
              fragment_start: fragment_start,
              insert_size: insert_size,
              mate_index: 0,
              read_sequence: read1_sequence,
              quality_sequence: read1_quality
            ),
            FastqRecord.new(
              read_name: read_name,
              pair_index: current_pair_index,
              fragment_start: fragment_start,
              insert_size: insert_size,
              mate_index: 1,
              read_sequence: read2_sequence,
              quality_sequence: read2_quality
            )
          )
        end
      end

      def build_read_pair_sequences(
        contig_sequence,
        fragment_start,
        insert_size,
        read1_starts_at_fragment_left : Bool,
      ) : Tuple(Slice(UInt8), Slice(UInt8))
        # Ranges that use '...' to exclude the given end value.
        # (1...4).to_a     # => [1, 2, 3]
        fragment_end = fragment_start + insert_size
        if read1_starts_at_fragment_left
          read1 = contig_sequence[fragment_start...(fragment_start + read1_length)]
          read2 = reverse_complement(
            sequence: contig_sequence[(fragment_end - read2_length)...fragment_end]
          )
        else
          read1 = reverse_complement(
            sequence: contig_sequence[(fragment_end - read1_length)...fragment_end]
          )
          read2 = contig_sequence[fragment_start...(fragment_start + read2_length)]
        end

        {read1, read2}
      end

      private def minimum_read_length_for_pair : Int32
        Math.max(read1_length, read2_length)
      end

      private def expected_read_pair_count(contig_length : Int32) : Int32
        sequenced_bases_per_pair = read1_length + read2_length
        (contig_length * average_depth / sequenced_bases_per_pair).to_i
      end

      # Report progress about 10 times per contig, at least once per read pair.
      private def progress_step_for(read_pair_count : Int32) : Int32
        progress_step = (read_pair_count / PROGRESS_REPORT_COUNT).to_i
        progress_step > 0 ? progress_step : 1
      end

      private def too_many_ambiguous_bases?(read_sequence : Slice(UInt8)) : Bool
        ambiguous_base_ratio(read_sequence) > max_ambiguous_ratio
      end

      private def ambiguous_base_ratio(read_sequence : Slice(UInt8)) : Float64
        read_sequence.count(BASE_N).to_f / read_sequence.size
      end

      def sample_insert_size(contig_length : Int32) : Int32
        min_insert_size = minimum_read_length_for_pair
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
