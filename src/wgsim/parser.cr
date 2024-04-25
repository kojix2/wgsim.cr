require "./version"
require "./utils"
require "./mutate/option"
require "./sequence/option"

require "nworkers"
require "option_parser"
require "../ext/option_parser"
require "colorize"

module Wgsim
  class Parser < OptionParser
    @option : (Mutate::Option | Sequence::Option)? = nil

    def initialize
      super
      @banner = <<-BANNER
      
      Program: wgsim (Crystal implementation of wgsim)
      Version: #{VERSION}
      BANNER

      on("mut", "mutate the reference") do
        @option = Mutate::Option.new
        @banner = "Usage: wgsim mut [options] <in.ref.fa>\n"

        on("-r FLOAT", "rate of mutations") do |v|
          @option.as(Mutate::Option).mutation_rate = v.to_f64
        end

        on("-R FLOAT", "fraction of indels") do |v|
          @option.as(Mutate::Option).indel_fraction = v.to_f64
        end

        on("-X FLOAT", "probability an indel is extended") do |v|
          @option.as(Mutate::Option).indel_extension_probability = v.to_f64
        end

        on("-S UINT64", "seed for random generator") do |v|
          @option.as(Mutate::Option).seed = v.to_u64
        end

        {% if flag?(:preview_mt) %}
          on("-t INT", "Number of threads [4]") do |v|
            # GitHub: kojix2/nworkers.cr
            Nworkers.set_workers(v.to_i)
          end
        {% end %}

        on("-h", "--help", "show this help message") do
          puts self
          exit
        end
      end

      on("seq", "generate the reads") do
        @option = Sequence::Option.new
        @banner = "Usage: wgsim seq [options] <in.ref.fa> <out.read1.fq> <out.read2.fq>\n"

        on("-e FLOAT", "base error rate") do |v|
          @option.as(Sequence::Option).error_rate = v.to_f64
        end

        on("-d INT", "outer distance between the two ends") do |v|
          @option.as(Sequence::Option).distance = v.to_i32
        end

        on("-s INT", "standard deviation") do |v|
          @option.as(Sequence::Option).std_deviation = v.to_i32
        end

        on("-D FLOAT", "average sequencing depth") do |v|
          @option.as(Sequence::Option).average_depth = v.to_f64
        end

        on("-1 INT", "length of the first read") do |v|
          @option.as(Sequence::Option).size_left = v.to_i32
        end

        on("-2 INT", "length of the second read") do |v|
          @option.as(Sequence::Option).size_right = v.to_i32
        end

        on("-A FLOAT", "Discard reads over FLOAT% ambiguous bases") do |v|
          @option.as(Sequence::Option).max_ambiguous_ratio = v.to_f64
        end

        on("-S UINT64", "seed for random generator") do |v|
          @option.as(Sequence::Option).seed = v.to_u64
        end

        {% if flag?(:preview_mt) %}
          on("-t INT", "Number of threads [4]") do |v|
            # GitHub: kojix2/nworkers.cr
            Nworkers.set_workers(v.to_i)
          end
        {% end %}

        on("-h", "--help", "show this help message") do
          puts self
          exit
        end
      end

      # on("version", "show version number") { show_version }
      invalid_option { |flag| Utils.exit_error("Invalid option: #{flag}") }
    end

    def parse(argv = ARGV)
      super
      case @option
      when Mutate::Option
        parse_mut(argv)
      when Sequence::Option
        parse_seq(argv)
      else
        STDERR.puts self
        exit 1
      end
      @option.not_nil!
    end

    def parse_mut(argv = ARGV)
      validate_arguments(argv, 1)
      @option.as(Mutate::Option).reference = Path.new(argv.shift)
      validate_file_exists(@option.as(Mutate::Option).reference)
    end

    def parse_seq(argv = ARGV)
      validate_arguments(argv, 3)
      @option.as(Sequence::Option).reference = Path.new(argv.shift)
      validate_file_exists(@option.as(Sequence::Option).reference)
      @option.as(Sequence::Option).output1 = Path.new(argv.shift)
      @option.as(Sequence::Option).output2 = Path.new(argv.shift)
    end

    def validate_arguments(argv, siz)
      unless argv.size == siz
        Utils.exit_error "Invalid number of arguments: #{argv.size} (expected #{siz})"
      end
    end

    def validate_file_exists(file)
      Utils.exit_error "File not found: #{file}" unless File.exists?(file.not_nil!)
    end
  end
end
