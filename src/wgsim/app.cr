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
      reference = mopts.reference.not_nil!
      mutation_simulator = MutationSimulator.new(
        mopts.mutation_rate,
        mopts.indel_fraction,
        mopts.indel_extension_probability,
        random: @random,
      )
      STDERR.puts "[wgsim] #{mopts}"
      ReadFasta.each_contig(reference) do |name, sequence|
        STDERR.puts "[wgsim] #{name} #{sequence.size} bp"
        normalized_sequence = ReadFasta.normalize_sequence(sequence)
        ref_bases = normalized_sequence.map do |n|
          RefBase.new(nucleotide: n, mutation_type: MutType::NOCHANGE)
        end
        2.times do |i|
          pname = "#{name.split.first}_#{i}"
          puts ">#{pname}"
          mutated_sequence = mutation_simulator.simulate_mutations(pname, ref_bases)
          seq = IO::Memory.new
          mutated_sequence.each do |b|
            case b.mutation_type
            when MutType::NOCHANGE, MutType::SUBSTITUTE
              seq.write_byte b.nucleotide
            when MutType::DELETE
            when MutType::INSERT
              seq.write_byte b.nucleotide
              ins = b.insertion
              seq.write ins if ins
            end
          end
          puts seq.to_s.gsub(/(.{80})/, "\\1\n")
        end
      end
    end

    def run_seq
      sopts = @options.seq
      reference = sopts.reference.not_nil!
      output1 = sopts.output1.not_nil!
      output2 = sopts.output2.not_nil!
      sequence_simulator = SequenceSimulator.new(
        sopts.mean_depth,
        sopts.distance,
        sopts.std_deviation,
        sopts.size_left,
        sopts.size_right,
        sopts.error_rate,
        sopts.max_ambiguous_ratio,
        random: @random,
      )

      output_fasta_1 = File.open(output1, "w")
      output_fasta_2 = File.open(output2, "w")

      ReadFasta.each_contig(reference) do |name, sequence|
        normalized_sequence = ReadFasta.normalize_sequence(sequence)
        sequence_simulator.run(name, normalized_sequence) do |record1, record2|
          output_fasta_1.puts record1
          output_fasta_2.puts record2
        end
      end

      output_fasta_1.close
      output_fasta_2.close
    end

    def run
      case @options.command
      when "mut"
        run_mut
      when "seq"
        run_seq
      end
    end
  end
end
