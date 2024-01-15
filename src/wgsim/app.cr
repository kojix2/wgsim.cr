require "./rand"
require "./read_fasta"
require "./ref_base"
require "./mutation_simulator"
require "./sequence_simulator"

module Wgsim
  class Simulator
    getter reference : Path
    getter output1 : Path
    getter output2 : Path

    def initialize(@options : Options)
      @reference = @options.reference.not_nil!
      @output1 = @options.output1.not_nil!
      @output2 = @options.output2.not_nil!
      @random = (seed = @options.seed) ? Rand.new(seed) : Rand.new

      @mutation_simulator = MutationSimulator.new(
        @options.mutation_rate,
        @options.indel_fraction,
        @options.indel_extension_probability,
        random: @random,
      )

      @sequence_simulator = SequenceSimulator.new(
        @options.total_pairs,
        @options.distance,
        @options.std_deviation,
        @options.size_left,
        @options.size_right,
        @options.error_rate,
        @options.max_ambiguous_ratio,
        random: @random,
      )
    end

    def calculate_total_seq_length
      contig_sequences = {} of String => Slice(RefBase)
      ReadFasta.each_contig(reference) do |name, sequence|
        puts "[wgsim] #{name} #{sequence.size} bp"

        normalized_seq = ReadFasta.normalize_sequence(sequence)
        ref_bases = normalized_seq.map do |n|
          RefBase.new(nucleotide: n, mutation_type: MutType::NOCHANGE)
        end
        contig_sequences[name] = ref_bases
      end

      num_contigs = contig_sequences.size
      total_seq_length = 0u64 # necessary to avoid overflow
      contig_sequences.values.each { |seq| total_seq_length += seq.size }

      {num_contigs, total_seq_length, contig_sequences}
    end

    def run
      puts "[wgsim] calculating the total length of the reference sequence..."
      num_contigs, total_seq_length, contig_sequences = calculate_total_seq_length
      puts "[wgsim] #{num_contigs} sequences, total length: #{total_seq_length} bp"

      output_fasta_1 = File.open(output1, "w")
      output_fasta_2 = File.open(output2, "w")

      @sequence_simulator.run(contig_sequences, total_seq_length, @mutation_simulator) do |record1, record2|
        output_fasta_1.puts record1
        output_fasta_2.puts record2
      end

      output_fasta_1.close
      output_fasta_2.close
    end
  end
end
