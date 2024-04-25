require "fastx"

require "./option"
require "./simulator"

module Wgsim
  module Mutate
    class Action
      def self.run(option)
        new(option).run
      end

      def initialize(@option : Option)
      end

      private def mopts
        @option
      end

      def run
        reference = mopts.reference.not_nil!

        mutation_simulator = Simulator.new(
          mopts.mutation_rate,
          mopts.indel_fraction,
          mopts.indel_extension_probability,
          mopts.seed
        )

        STDERR.puts "[wgsim] #{mopts}"
        Fastx::Fasta::Reader.open(reference) do |reader|
          reader.each do |name, sequence|
            STDERR.puts "[wgsim] #{name} #{sequence.size} bp"
            reference_sequence = Fastx.normalize_sequence(sequence)
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
      end
    end
  end
end
