require "./version"
require "./config"
require "./mutation_options"
require "./sequence_options"
require "./utils"

require "option_parser"
require "../ext/option_parser"
require "colorize"

module Wgsim
  class Parser < OptionParser
    getter mutation_options : MutationOptions?
    getter sequence_options : SequenceOptions?
    getter command : String?

    def initialize
      super
      @command = nil
      @mutation_options = nil
      @sequence_options = nil
      @banner = <<-BANNER
        Program: wgsim (Crystal implementation of wgsim)
        Version: #{VERSION}
      BANNER

      on("mut", "mutate the reference") do
        mutation_options = MutationOptions.new
        m_on("-r FLOAT", "rate of mutations", :mutation_rate)
        m_on("-R FLOAT", "fraction of indels", :indel_fraction)
        m_on("-X FLOAT", "probability an indel is extended", :indel_extension_probability)
        m_on("-S UINT64", "seed for random generator", :seed)
        {% if flag?(:preview_mt) %}
          on("-t INT", "Number of threads [4]") { |v| set_threads(v.to_i) }
        {% end %}
        on("--help", "show this help message") { show_help }
      end
      on("seq", "generate the reads") do
        sequence_options = SequenceOptions.new
        s_on("-e FLOAT", "base error rate", :error_rate)
        s_on("-d INT", "outer distance between the two ends", :distance)
        s_on("-s INT", "standard deviation", :std_deviation)
        s_on("-N INT64", "number of read pairs", :total_pairs)
        s_on("-1 INT", "length of the first read", :size_left)
        s_on("-2 INT", "length of the second read", :size_right)
        s_on("-S UINT64", "seed for random generator", :seed)
        s_on("-A FLOAT", "Discard reads over FLOAT% ambiguous bases", :max_ambiguous_ratio)
        {% if flag?(:preview_mt) %}
          on("-t INT", "Number of threads [4]") { |v| set_threads(v.to_i) }
        {% end %}
        on("--help", "show this help message") { show_help }
      end
      on("help", "show this help message") { show_help }
      on("version", "show version number") { show_version }
      invalid_option { |flag| Utils.print_error!("Invalid option: #{flag}") }
    end

    def parse(argv = ARGV) : MutationOptions | SequenceOptions
      case command
      when "mut"
        parse_mut(argv)
      when "seq"
        parse_seq(argv)
      else
        Utils.print_error!("Invalid command: #{command}")
      end
    end

    def parse_mut(argv = ARGV) : MutationOptions
      mutation_options.not_nil!.reference = Path.new(argv.shift)
      validate_file_exists(mutation_options.not_nil!.reference)
      mutation_options.not_nil!
    end

    def parse_seq(argv = ARGV) : SequenceOptions
      validate_arguments(argv)
      sequence_options.not_nil!.reference = Path.new(argv.shift)
      validate_file_exists(sequence_options.not_nil!.reference)
      sequence_options.not_nil!.output1 = Path.new(argv.shift)
      sequence_options.not_nil!.output2 = Path.new(argv.shift)
      sequence_options.not_nil!
    end

    def show_version
      puts Wgsim::VERSION
      exit
    end

    def show_help
      puts self
      exit
    end

    def validate_arguments(argv)
      case argv.size
      when 3
        # OK
      when 0
        STDERR.puts self
        exit 1
      else
        Utils.print_error!("Invalid arguments")
        exit 1
      end
    end

    def validate_file_exists(file)
      Utils.print_error!("File not found: #{file}") unless File.exists?(file.not_nil!)
    end

    {% if flag?(:preview_mt) %}
      private def set_threads(n)
        if n > 4
          (n - 4).times { Crystal::Scheduler.add_worker }
        elsif n < 4 && n > 0
          (4 - n).times { Crystal::Scheduler.remove_worker }
        else
          Utils.print_error!("Invalid number of threads: #{n}")
        end
      end
    {% end %}
  end
end
