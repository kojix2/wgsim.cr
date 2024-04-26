require "./version"
require "./mutate/option"
require "./sequence/option"
require "./action"

require "nworkers"
require "option_parser"
require "colorize"

module Wgsim
  class Parser < OptionParser
    getter option : (Mutate::Option | Sequence::Option)? = nil
    getter action : Action?
    getter help_message : String

    private def mopt
      option.as(Mutate::Option)
    end

    private def sopt
      option.as(Sequence::Option)
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
      Source:  #{{{ `crystal eval 'require "yaml"; puts YAML.parse(File.read("#{__DIR__}/../../shard.yml"))["repository"]'`.chomp.stringify }}}

      BANNER

      on("mut", "mutate the reference") do
        _set_option_(Mutate, "Usage: wgsim mut [options] <in.ref.fa>\n")

        on("-s", "--substitution-rate FLOAT",
          "rate of base substitutions [#{mopt.substitution_rate}]") do |v|
          mopt.substitution_rate = v.to_f64
        end

        on("-i", "--insertion-rate FLOAT",
          "rate of insertions [#{mopt.insertion_rate}]") do |v|
          mopt.insertion_rate = v.to_f64
        end

        on("-d", "--deletion-rate FLOAT",
          "rate of deletions [#{mopt.deletion_rate}]") do |v|
          mopt.deletion_rate = v.to_f64
        end

        on("-I", "--ins-ext-prob FLOAT",
          "probability an insertion is extended [#{mopt.insertion_extension_probability}]") do |v|
          mopt.insertion_extension_probability = v.to_f64
        end

        on("-D", "--del-ext-prob FLOAT",
          "probability a deletion is extended [#{mopt.deletion_extension_probability}]") do |v|
          mopt.deletion_extension_probability = v.to_f64
        end

        on("-p", "--ploidy UINT8", "ploidy [#{mopt.ploidy}]") do |v|
          mopt.ploidy = v.to_u8
        end

        on("-S", "--seed UINT64", "seed for random generator") do |v|
          mopt.seed = v.to_u64
        end

        _on_threads_

        _on_debug_

        _on_help_
      end

      on("seq", "generate the reads") do
        _set_option_(Sequence, "Usage: wgsim seq [options] <in.ref.fa> <out.read1.fq> <out.read2.fq>\n")

        on("-e", "--error-rate FLOAT", "base error rate [#{sopt.error_rate}]") do |v|
          sopt.error_rate = v.to_f64
        end

        on("-d", "--distance INT",
          "outer distance between the two ends [#{sopt.distance}]") do |v|
          sopt.distance = v.to_i32
        end

        on("-s", "--std-dev FLOAT",
          "standard deviation [#{sopt.std_deviation}]") do |v|
          sopt.std_deviation = v.to_i32
        end

        on("-D", "--depth FLOAT",
          "average sequencing depth [#{sopt.average_depth}]") do |v|
          sopt.average_depth = v.to_f64
        end

        on("-1", "--size-left INT",
          "length of the first read [#{sopt.size_left}]") do |v|
          sopt.size_left = v.to_i32
        end

        on("-2", "--size-right INT",
          "length of the second read [#{sopt.size_right}]") do |v|
          sopt.size_right = v.to_i32
        end

        on("-A", "--ambiguous-ratio FLOAT",
          "Discard reads over FLOAT% ambiguous bases [#{sopt.max_ambiguous_ratio}]") do |v|
          sopt.max_ambiguous_ratio = v.to_f64
        end

        on("-S", "--seed UINT64", "seed for random generator") do |v|
          sopt.seed = v.to_u64
        end

        _on_threads_

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

    def parse(argv = ARGV) : Tuple(Action?, (Mutate::Option | Sequence::Option)?)
      super
      case action
      when Action::Mutate
        mopt.reference = Path.new(argv.shift)
        {action, mopt}
      when Action::Sequence
        sopt.reference = Path.new(argv.shift)
        sopt.output1 = Path.new(argv.shift)
        sopt.output2 = Path.new(argv.shift)
        {action, sopt}
      else
        {action, nil}
      end
    end
  end
end
