require "./version"
require "./mutate/option"
require "./sequence/option"
require "./action"

require "nworkers"
require "option_parser"
require "colorize"

module Wgsim
  class Parser < OptionParser
    getter option : (Mutate::Option | Sequence::Option | Generate::Option)? = nil
    getter action : Action?
    getter help_message : String

    private def mopt
      option.as(Mutate::Option)
    end

    private def sopt
      option.as(Sequence::Option)
    end

    private def gopt
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

    macro _on_threads_
    {% if flag?(:preview_mt) %}
      on("-t", "--threads INT", "Number of threads [#{NWorkers.size}]") do |v|
        # GitHub: kojix2/nworkers.cr
        NWorkers.set_worker(v.to_i)
      end
    {% end %}
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

      BANNER

      on("mut", "Add mutations to reference sequences") do
        _set_option_(Mutate,
          "About: Add mutations to reference sequences\n" \
          "Usage: wgsim mut [options] -f <in.ref.fa>\n"
        )

        on("-f", "--file FILE", "Input file for the reference sequence") do |v|
          mopt.reference = Path.new(v)
        end

        on("-s", "--sub-rate FLOAT",
          "Rate of base substitutions [#{mopt.substitution_rate}]") do |v|
          mopt.substitution_rate = v.to_f64
        end

        on("-i", "--ins-rate FLOAT",
          "Rate of insertions [#{mopt.insertion_rate}]") do |v|
          mopt.insertion_rate = v.to_f64
        end

        on("-d", "--del-rate FLOAT",
          "Rate of deletions [#{mopt.deletion_rate}]") do |v|
          mopt.deletion_rate = v.to_f64
        end

        on("-I", "--ins-ext-prob FLOAT",
          "Probability an insertion is extended [#{mopt.insertion_extension_probability}]") do |v|
          mopt.insertion_extension_probability = v.to_f64
        end

        on("-D", "--del-ext-prob FLOAT",
          "Probability a deletion is extended [#{mopt.deletion_extension_probability}]") do |v|
          mopt.deletion_extension_probability = v.to_f64
        end

        on("-p", "--ploidy UINT8", "Number of chromosome copies in output fasta [#{mopt.ploidy}]") do |v|
          mopt.ploidy = v.to_u8
        end

        on("-S", "--seed UINT64", "Seed for random generator") do |v|
          mopt.seed = v.to_u64
        end

        _on_threads_

        _on_debug_

        _on_help_
      end

      on("seq", "Simulate pair-end sequencing") do
        _set_option_(Sequence,
          "About: Simulate pair-end sequencing\n" \
          "Usage: wgsim seq [options] -f <in.ref.fa> -1 <out.read1.fq> -2 <out.read2.fq>\n"
        )

        on("-f", "--file FILE", "Input file for the reference sequence") do |v|
          sopt.reference = Path.new(v)
        end

        on("-1", "--output1 FILE", "Output file for the first read") do |v|
          sopt.output1 = Path.new(v)
        end

        on("-2", "--output2 FILE", "Output file for the second read") do |v|
          sopt.output2 = Path.new(v)
        end

        on("-e", "--error-rate FLOAT", "Base error rate [#{sopt.error_rate}]") do |v|
          sopt.error_rate = v.to_f64
        end

        on("-d", "--distance INT",
          "Outer distance between the two ends [#{sopt.distance}]") do |v|
          sopt.distance = v.to_i32
        end

        on("-s", "--std-dev FLOAT",
          "Standard deviation of the insert size [#{sopt.std_deviation}]") do |v|
          sopt.std_deviation = v.to_i32
        end

        on("-D", "--depth FLOAT",
          "Average sequencing depth [#{sopt.average_depth}]") do |v|
          sopt.average_depth = v.to_f64
        end

        on("-L", "--size-left INT", "Length of the first read [#{sopt.size_left}]") do |v|
          sopt.size_left = v.to_i32
        end

        on("-R", "--size-right INT", "Length of the second read [#{sopt.size_right}]") do |v|
          sopt.size_right = v.to_i32
        end

        on("-A", "--ambiguous-ratio FLOAT",
          "Discard if the fraction of N(ambiguous) bases higher than FLOAT [#{sopt.max_ambiguous_ratio}]") do |v|
          sopt.max_ambiguous_ratio = v.to_f64
        end

        on("-S", "--seed UINT64", "Seed for random generator") do |v|
          sopt.seed = v.to_u64
        end

        _on_threads_

        _on_debug_

        _on_help_
      end

      on("gen", "Generate random reference fasta") do
        _set_option_(Generate,
          "About: Generate random reference fasta\n" \
          "Usage: wgsim gen [options]\n"
        )

        on("-l", "--length INT", "Length of the reference sequence [\"1000,700\"]") do |v|
          gopt.chromosome_length = v.split(",").map(&.to_i32)
        end

        on("-s", "--seed UINT64", "Seed for random generator") do |v|
          gopt.seed = v.to_u64
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
        STDERR.puts "[wgsim.cr] ERROR: #{flag} is not a valid option."
        STDERR.puts self
        exit(1)
      end

      missing_option do |flag|
        STDERR.puts "[wgsim.cr] ERROR: #{flag} option expects an argument."
        STDERR.puts self
        exit(1)
      end
    end

    def parse(argv = ARGV) : Tuple(Action?, (Mutate::Option | Sequence::Option | Generate::Option)?)
      super
      case action
      when Action::Mutate
        {action, mopt}
      when Action::Sequence
        {action, sopt}
      when Action::Generate
        {action, gopt}
      else
        {action, nil}
      end
    end
  end
end
