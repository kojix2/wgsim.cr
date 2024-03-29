require "./version"
require "./options"
require "./utils"

require "option_parser"
require "../ext/option_parser"
require "colorize"

module Wgsim
  class Parser < OptionParser
    def initialize
      super
      @options = Options.new
      @banner = <<-BANNER
        Program: wgsim (Crystal implementation of wgsim)
        Version: #{VERSION}
      BANNER

      on("mut", "mutate the reference") do
        @options.command = "mut"
        @banner = "  Usage: wgsim mut [options] <in.ref.fa>\n"
        m_on("-r FLOAT", "rate of mutations", :mutation_rate)
        m_on("-R FLOAT", "fraction of indels", :indel_fraction)
        m_on("-X FLOAT", "probability an indel is extended", :indel_extension_probability)
        on("-S UINT64", "seed for random generator") { |v| @options.seed = v.to_u64 }
        {% if flag?(:preview_mt) %}
          on("-t INT", "Number of threads [4]") { |v| set_threads(v.to_i) }
        {% end %}
        on("--help", "show this help message") { show_help! }
      end

      on("seq", "generate the reads") do
        @options.command = "seq"
        @banner = "  Usage: wgsim seq [options] <in.ref.fa> <out.read1.fq> <out.read2.fq>\n"
        s_on("-e FLOAT", "base error rate", :error_rate)
        s_on("-d INT", "outer distance between the two ends", :distance)
        s_on("-s INT", "standard deviation", :std_deviation)
        s_on("-D FLOAT", "average sequencing depth", :average_depth)
        s_on("-1 INT", "length of the first read", :size_left)
        s_on("-2 INT", "length of the second read", :size_right)
        s_on("-A FLOAT", "Discard reads over FLOAT% ambiguous bases", :max_ambiguous_ratio)
        on("-S UINT64", "seed for random generator") { |v| @options.seed = v.to_u64 }
        {% if flag?(:preview_mt) %}
          on("-t INT", "Number of threads [4]") { |v| set_threads(v.to_i) }
        {% end %}
        on("--help", "show this help message") { show_help! }
      end
      on("version", "show version number") { show_version }
      invalid_option { |flag| Utils.print_error!("Invalid option: #{flag}") }
    end

    def parse(argv = ARGV)
      super
      case @options.command
      when "mut"
        parse_mut(argv)
      when "seq"
        parse_seq(argv)
      when ""
        show_help!(1)
      else
        Utils.print_error!("Invalid command: #{@options.command}")
      end
      @options
    end

    def parse_mut(argv = ARGV)
      validate_arguments(argv, 1)
      @options.mut.reference = Path.new(argv.shift)
      validate_file_exists(@options.mut.reference)
    end

    def parse_seq(argv = ARGV)
      validate_arguments(argv, 3)
      @options.seq.reference = Path.new(argv.shift)
      validate_file_exists(@options.seq.reference)
      @options.seq.output1 = Path.new(argv.shift)
      @options.seq.output2 = Path.new(argv.shift)
    end

    def show_version
      puts Wgsim::VERSION
      exit
    end

    def show_help!(n = 0)
      show_help(n)
      exit(n)
    end

    def show_help(n = 0)
      if n == 0
        puts
        puts self
        puts
      else
        STDERR.puts
        STDERR.puts self
        STDERR.puts
      end
    end

    def validate_arguments(argv, siz)
      case argv.size
      when siz
        # OK
      when 0
        show_help(1)
        Utils.print_error! "Use --help for more information\n"
      else
        show_help(1)
        Utils.print_error! "Invalid arguments\n"
      end
    end

    def validate_file_exists(file)
      Utils.print_error! "File not found: #{file}" unless File.exists?(file.not_nil!)
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
