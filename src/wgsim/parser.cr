require "./version"
require "./console"
require "./mutate/option"
require "./sequencing/option"
require "./action"

require "option_parser"
require "colorize"

module Wgsim
  class Parser < OptionParser
    getter option : (Mutate::Option | Sequencing::Option | Generate::Option)? = nil
    getter action : Action?
    getter help_message : String

    private def mutation_options
      option.as(Mutate::Option)
    end

    private def sequencing_options
      option.as(Sequencing::Option)
    end

    private def generation_options
      option.as(Generate::Option)
    end

    macro _on_debug_
      on("--debug", "Show backtrace on error") do
        CLI.debug = true
      end
    end

    macro _on_help_
      on("-h", "--help", "Show this help") do
        @action = Action::Help
      end

      # Crystal's OptionParser returns to its initial state after parsing
      # by `with_preserved_state`. This also initialises @flags.
      # @help_message is needed to store subcommand messages.
      @help_message = self.to_s
    end

    macro _set_option_(klass, banner)
      @action = Action::{{klass}}
      @option = {{klass}}::Option.new
      @handlers.clear
      @flags.clear
      @banner = {{banner}}
    end

    def initialize
      super
      @help_message = ""

      @banner = <<-BANNER

      Program: wgsim (Crystal implementation of wgsim)
      Version: #{VERSION}
      Source:  https://github.com/kojix2/wgsim.cr

      Commands:
      BANNER

      on("mut", "Add biological mutations to reference sequences") do
        _set_option_(Mutate,
          "About: Add biological mutations to reference sequences\n" \
          "Usage: wgsim mut [options] -r <in.ref.fa> -o <out.fa> -l <out.tsv>\n"
        )

        on("-r", "--reference FILE", "Input reference FASTA (required)") do |v|
          mutation_options.reference = Path.new(v)
        end

        on("-o", "--mutated-fasta FILE", "Output mutated FASTA (required)") do |v|
          mutation_options.mutated_fasta = Path.new(v)
        end

        on("-l", "--mutation-log FILE", "Output mutation event log TSV (required)") do |v|
          mutation_options.mutation_event_log = Path.new(v)
        end

        on("-s", "--sub-rate FLOAT",
          "Per-base substitution probability [#{mutation_options.substitution_rate}]") do |v|
          mutation_options.substitution_rate = v.to_f64
        end

        on("-i", "--ins-rate FLOAT",
          "Per-base insertion probability [#{mutation_options.insertion_rate}]") do |v|
          mutation_options.insertion_rate = v.to_f64
        end

        on("-d", "--del-rate FLOAT",
          "Per-base deletion-start probability [#{mutation_options.deletion_rate}]") do |v|
          mutation_options.deletion_rate = v.to_f64
        end

        on("-I", "--ins-extend FLOAT",
          "Probability of extending an insertion by one base " \
          "[#{mutation_options.insertion_extension_probability}]") do |v|
          mutation_options.insertion_extension_probability = v.to_f64
        end

        on("-D", "--del-extend FLOAT",
          "Probability of extending an open deletion by one base " \
          "[#{mutation_options.deletion_extension_probability}]") do |v|
          mutation_options.deletion_extension_probability = v.to_f64
        end

        on("-p", "--ploidy UINT8",
          "Number of mutated chromosome copies per input sequence " \
          "[#{mutation_options.ploidy}]") do |v|
          mutation_options.ploidy = v.to_u8
        end

        on("-S", "--seed UINT64", "Random seed") do |v|
          mutation_options.seed = v.to_u64
        end

        _on_debug_

        _on_help_
      end

      on("seq", "Simulate paired-end sequencing reads") do
        _set_option_(Sequencing,
          "About: Simulate paired-end sequencing reads\n" \
          "Usage: wgsim seq [options] -r <in.ref.fa> -1 <out.read1.fq> -2 <out.read2.fq>\n"
        )

        on("-r", "--reference FILE", "Input reference FASTA (required)") do |v|
          sequencing_options.reference = Path.new(v)
        end

        on("-1", "--read1-fastq FILE", "Output FASTQ for read 1 (required)") do |v|
          sequencing_options.read1_fastq = Path.new(v)
        end

        on("-2", "--read2-fastq FILE", "Output FASTQ for read 2 (required)") do |v|
          sequencing_options.read2_fastq = Path.new(v)
        end

        on("-e", "--error-rate FLOAT",
          "Per-base sequencing error probability " \
          "[#{sequencing_options.error_rate}]") do |v|
          sequencing_options.error_rate = v.to_f64
        end

        on("-m", "--mean-insert INT",
          "Mean insert size [#{sequencing_options.mean_insert_size}]") do |v|
          sequencing_options.mean_insert_size = v.to_i32
        end

        on("-s", "--insert-sd FLOAT",
          "Insert size standard deviation [#{sequencing_options.insert_size_std_dev}]") do |v|
          sequencing_options.insert_size_std_dev = v.to_i32
        end

        on("-D", "--depth FLOAT",
          "Average sequencing depth [#{sequencing_options.average_depth}]") do |v|
          sequencing_options.average_depth = v.to_f64
        end

        on("-L", "--read1-len INT", "Read 1 length [#{sequencing_options.read1_length}]") do |v|
          sequencing_options.read1_length = v.to_i32
        end

        on("-R", "--read2-len INT", "Read 2 length [#{sequencing_options.read2_length}]") do |v|
          sequencing_options.read2_length = v.to_i32
        end

        on("-A", "--max-n-ratio FLOAT",
          "Discard a read pair if either read has a higher N fraction " \
          "[#{sequencing_options.max_ambiguous_ratio}]") do |v|
          sequencing_options.max_ambiguous_ratio = v.to_f64
        end

        on("-S", "--seed UINT64", "Random seed") do |v|
          sequencing_options.seed = v.to_u64
        end

        _on_debug_

        _on_help_
      end

      on("gen", "Generate random reference FASTA") do
        _set_option_(Generate,
          "About: Generate random reference FASTA\n" \
          "Usage: wgsim gen [options]\n"
        )

        on("-l", "--chromosome-lengths INT",
          "Comma-separated chromosome lengths " \
          "[\"#{generation_options.chromosome_lengths.join(",")}\"]") do |v|
          generation_options.chromosome_lengths = v.split(",").map(&.to_i32)
        end

        on("-S", "--seed UINT64", "Random seed") do |v|
          generation_options.seed = v.to_u64
        end

        _on_debug_

        _on_help_
      end

      separator

      _on_debug_

      on("-v", "--version", "Show version") do
        @action = Action::Version
      end

      _on_help_

      invalid_option do |flag|
        Console.error("#{flag} is not a valid option.")
        STDERR.puts self
        exit(1)
      end

      missing_option do |flag|
        Console.error("#{flag} option expects an argument.")
        STDERR.puts self
        exit(1)
      end
    end

    def parse(
      argv = ARGV,
    ) : Tuple(Action?, (Mutate::Option | Sequencing::Option | Generate::Option)?)
      super
      case action
      when Action::Mutate
        {action, mutation_options}
      when Action::Sequencing
        {action, sequencing_options}
      when Action::Generate
        {action, generation_options}
      else
        {action, nil}
      end
    end
  end
end
