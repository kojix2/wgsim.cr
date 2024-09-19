require "fastx"
require "./mutate/option"
require "./mutate/core"

module Wgsim
  class Mutate
    getter option : Option
    getter reference : Path
    getter output_fasta : Path
    getter output_mutation : Path # Should be a VCF in the future
    getter core : Core

    def self.run(option)
      new(option).run
    end

    def initialize(@option : Option)
      @reference = option.reference || raise("Reference sequence is required")
      @output_fasta = option.output_fasta || raise("Output FASTA file is required")
      @output_mutation = option.output_mutation || raise("Output mutation file is required")
      @core = Core.new(
        substitution_rate: option.substitution_rate,
        insertion_rate: option.insertion_rate,
        deletion_rate: option.deletion_rate,
        insertion_extension_probability: option.insertion_extension_probability,
        deletion_extension_probability: option.deletion_extension_probability,
        seed: option.seed
      )
    end

    def run
      log_parameters
      process_sequences
    end

    private def log_parameters
      option.summary.split("\n").each do |line|
        STDERR.puts "[wgsim] # #{line}"
      end
    end

    private def process_sequences
      reader = Fastx::Fasta::Reader.new(reference)
      fo = File.open(output_fasta, "w")
      mo = File.open(output_mutation, "w")
      begin
        reader.each do |name, sequence|
          STDERR.puts "[wgsim] #{name} #{sequence.size} bp"
          process_sequence(name, sequence, fout: fo, mout: mo)
        end
      rescue ex
        STDERR.puts "Error processing sequences: #{ex.message}"
      ensure
        reader.try &.close
        fo.try &.close
        mo.try &.close
      end
    end

    private def process_sequence(name : String, sequence : IO::Memory, fout : IO, mout : IO)
      reference_sequence = Fastx.normalize_sequence(sequence)
      if option.ploidy == 1
        simulate_and_output_sequence(name, reference_sequence, fo: fout, mo: mout)
      else
        option.ploidy.times do |i|
          simulate_and_output_sequence(name, reference_sequence, i + 1, fo: fout, mo: mout)
        end
      end
    end

    private def simulate_and_output_sequence(name : String, reference_sequence : Slice(UInt8), index = nil, fo = STDOUT, mo = STDERR)
      pname = "#{name.split.first}"
      pname += "_#{index}" if index
      fo.puts ">#{pname}"
      mutated_sequence, event_log = core.simulate_mutations(reference_sequence)
      event_log.each do |ev|
        ev.name = pname
        ev.to_s(mo)
        mo.puts
      end
      fo.puts mutated_sequence.format
    end
  end
end
