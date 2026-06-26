module Wgsim
  class Sequencing
    class Option
      MIN_PROBABILITY = 0.0
      MAX_PROBABILITY = 1.0

      DEFAULT_ERROR_RATE          = 0.01
      DEFAULT_MEAN_INSERT_SIZE    =  500
      DEFAULT_INSERT_SIZE_STD_DEV =   50
      DEFAULT_AVERAGE_DEPTH       = 10.0
      DEFAULT_READ1_LENGTH        =  100
      DEFAULT_READ2_LENGTH        =  100
      DEFAULT_MAX_AMBIGUOUS_RATIO = 0.05

      property seed : UInt64?
      property error_rate : Float64 = DEFAULT_ERROR_RATE
      property mean_insert_size : Int32 = DEFAULT_MEAN_INSERT_SIZE
      property insert_size_std_dev : Int32 = DEFAULT_INSERT_SIZE_STD_DEV
      property average_depth : Float64 = DEFAULT_AVERAGE_DEPTH
      property read1_length : Int32 = DEFAULT_READ1_LENGTH
      property read2_length : Int32 = DEFAULT_READ2_LENGTH
      property max_ambiguous_ratio : Float64 = DEFAULT_MAX_AMBIGUOUS_RATIO
      property reference : Path?
      property read1_fastq : Path?
      property read2_fastq : Path?

      def summary
        <<-SUMMARY
        Reference: #{reference}
        Seed: #{seed.nil? ? "random" : seed}
        Error rate: #{error_rate}
        Mean insert size: #{mean_insert_size}
        Insert size standard deviation: #{insert_size_std_dev}
        Average depth of coverage: #{average_depth}
        Read 1 length: #{read1_length}
        Read 2 length: #{read2_length}
        Maximum ambiguous base ratio: #{max_ambiguous_ratio}
        Read 1 FASTQ: #{read1_fastq}
        Read 2 FASTQ: #{read2_fastq}
        SUMMARY
      end

      def validate! : Nil
        validate_probability("error rate", error_rate, allow_zero: false)
        validate_probability("maximum ambiguous base ratio", max_ambiguous_ratio)

        raise ArgumentError.new("Mean insert size must be greater than 0") if mean_insert_size <= 0
        if insert_size_std_dev < 0
          raise ArgumentError.new("Insert size standard deviation must be >= 0")
        end
        raise ArgumentError.new("Average depth must be >= 0.0") if average_depth < 0.0
        raise ArgumentError.new("Read 1 length must be greater than 0") if read1_length <= 0
        raise ArgumentError.new("Read 2 length must be greater than 0") if read2_length <= 0
      end

      private def validate_probability(
        name : String,
        value : Float64,
        allow_zero : Bool = true,
      ) : Nil
        lower_bound_ok = allow_zero ? value >= MIN_PROBABILITY : value > MIN_PROBABILITY
        unless lower_bound_ok && value <= MAX_PROBABILITY
          lower_bound = allow_zero ? MIN_PROBABILITY.to_s : "greater than #{MIN_PROBABILITY}"
          raise ArgumentError.new("#{name} must be #{lower_bound} and <= #{MAX_PROBABILITY}")
        end
      end
    end
  end
end
