require "./version"
require "./config"
require "./utils"

require "option_parser"
require "../ext/option_parser"
require "colorize"

module Wgsim
  class Parser < OptionParser
    getter config : Config

    def initialize
      super
      @config = Config.new
      @banner = <<-BANNER
        Program: wgsim (Crystal implementation of wgsim)
        Version: #{VERSION}
        Usage:   wgsim [options] <in.ref.fa> <out.read1.fq> <out.read2.fq>
        Options:
      BANNER

      _on("-e FLOAT", "base error rate", :error_rate)
      _on("-d INT", "outer distance between the two ends", :distance)
      _on("-s INT", "standard deviation", :std_deviation)
      _on("-N INT64", "number of read pairs", :total_pairs)
      _on("-1 INT", "length of the first read", :size_left)
      _on("-2 INT", "length of the second read", :size_right)
      _on("-r FLOAT", "rate of mutations", :mutation_rate)
      _on("-R FLOAT", "fraction of indels", :indel_fraction)
      _on("-X FLOAT", "probability an indel is extended", :indel_extension_probability)
      _on("-S UINT64", "seed for random generator", :seed)
      _on("-A FLOAT", "Discard reads over FLOAT% ambiguous bases", :max_ambiguous_ratio)
      {% if flag?(:preview_mt) %}
        on("-t INT", "Number of threads [4]") { |v| set_threads(v.to_i) }
      {% end %}
      on("--help", "show this help message") { show_help }
      on("--version", "show version number") { show_version }
      invalid_option { |flag| Utils.print_error!("Invalid option: #{flag}") }
    end

    def parse(argv = ARGV) : Config
      super
      validate_arguments(argv)
      config.reference = Path.new(argv.shift)
      validate_file_exists(config.reference)
      config.output1 = Path.new(argv.shift)
      config.output2 = Path.new(argv.shift)
      config
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
