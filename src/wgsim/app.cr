require "./rand"
require "./read_fasta"
require "./ref_base"
require "./mutation_simulator"
require "./sequence_simulator"

module Wgsim
  class Simulator
    def initialize(@options : Options)
      @random = (seed = @options.seed) ? Rand.new(seed) : Rand.new
    end

    def run_mut
      mopts = @options.mut
      @reference = mopts.reference.not_nil!
      @mutation_simulator = MutationSimulator.new(
        mopts.mutation_rate,
        mopts.indel_fraction,
        mopts.indel_extension_probability,
        random: @random,
      )
    end

    def run_seq
      sopts = @options.seq
      @reference = sopts.reference.not_nil!
      @output1 = sopts.output1.not_nil!
      @output2 = sopts.output2.not_nil!
      @sequence_simulator = SequenceSimulator.new(
        sopts.total_pairs,
        sopts.distance,
        sopts.std_deviation,
        sopts.size_left,
        sopts.size_right,
        sopts.error_rate,
        sopts.max_ambiguous_ratio,
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
