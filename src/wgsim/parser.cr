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
    property help_message : String

    private def mopt
      option.as(Mutate::Option)
    end

    private def sopt
      option.as(Sequence::Option)
    end

    macro _on_debug_
      on("-d", "--debug", "Show backtrace on error") do
        CLI.debug = true
      end
    end

    macro _on_help_
      on("-h", "--help", "Show this help") do
        action = Action::Help
      end

      # Crystal's OptionParser returns to its initial state after parsing
      # by `with_preserved_state`. This also initialises @flags.
      # @help_message is needed to store subcommand messages.
      @help_message = self.to_s
    end

    macro _set_option_(klass, banner)
      @option = {{klass}}::Option.new
      @handlers.clear
      @flags.clear
      self.banner = {{banner}}
    end

    def initialize
      super
      @help_message = ""

      self.banner = <<-BANNER
      
      Program: wgsim (Crystal implementation of wgsim)
      Version: #{VERSION}
      BANNER

      on("mut", "mutate the reference") do
        _set_option_(Mutate, "Usage: wgsim mut [options] <in.ref.fa>\n")

        on("-r FLOAT", "rate of mutations") do |v|
          mopt.mutation_rate = v.to_f64
        end

        on("-R FLOAT", "fraction of indels") do |v|
          mopt.indel_fraction = v.to_f64
        end

        on("-X FLOAT", "probability an indel is extended") do |v|
          mopt.indel_extension_probability = v.to_f64
        end

        on("-S UINT64", "seed for random generator") do |v|
          mopt.seed = v.to_u64
        end

        {% if flag?(:preview_mt) %}
          on("-t INT", "Number of threads [4]") do |v|
            # GitHub: kojix2/nworkers.cr
            NWorkers.set_worker(v.to_i)
          end
        {% end %}

        _on_debug_

        _on_help_
      end

      on("seq", "generate the reads") do
        _set_option_(Sequence, "Usage: wgsim seq [options] <in.ref.fa> <out.read1.fq> <out.read2.fq>\n")

        on("-e FLOAT", "base error rate") do |v|
          sopt.error_rate = v.to_f64
        end

        on("-d INT", "outer distance between the two ends") do |v|
          sopt.distance = v.to_i32
        end

        on("-s INT", "standard deviation") do |v|
          sopt.std_deviation = v.to_i32
        end

        on("-D FLOAT", "average sequencing depth") do |v|
          sopt.average_depth = v.to_f64
        end

        on("-1 INT", "length of the first read") do |v|
          sopt.size_left = v.to_i32
        end

        on("-2 INT", "length of the second read") do |v|
          sopt.size_right = v.to_i32
        end

        on("-A FLOAT", "Discard reads over FLOAT% ambiguous bases") do |v|
          sopt.max_ambiguous_ratio = v.to_f64
        end

        on("-S UINT64", "seed for random generator") do |v|
          sopt.seed = v.to_u64
        end

        {% if flag?(:preview_mt) %}
          on("-t INT", "Number of threads [4]") do |v|
            # GitHub: kojix2/nworkers.cr
            NWorkers.set_worker(v.to_i)
          end
        {% end %}

        _on_debug_

        _on_help_
      end

      _on_debug_

      on("-v", "--version", "Show version") do
        action = Action::Version
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
