require "./rand"
require "./read_fasta"
require "./ref_base"
require "./mutation_simulator"
require "./sequence_simulator"

module Wgsim
  class Application
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
        reference_sequence = ReadFasta.normalize_sequence(sequence) do |n|
          RefBase.new(nucleotide: n, mutation_type: MutType::NOCHANGE)
        end
        2.times do |i|
          pname = "#{name.split.first}_#{i}"
          puts ">#{pname}"
          mutated_sequence = mutation_simulator.simulate_mutations(pname, reference_sequence)
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
        sopts.average_depth,
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

      names = [] of String
      channel = Channel(String).new

      ReadFasta.each_contig(reference) do |name, sequence|
        names << name
        normalized_sequence = ReadFasta.normalize_sequence(sequence)
        spawn do
          sequence_simulator.run(name, normalized_sequence) do |record1, record2|
            output_fasta_1.puts record1
            output_fasta_2.puts record2
          end
          channel.send name
        end
      end

      while names.present?
        name = channel.receive
        names.delete name
        STDERR.puts "[wgsim] #{name} done"
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
