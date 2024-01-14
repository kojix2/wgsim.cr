require "compress/gzip"

module Wgsim
  module ReadFasta
    extend self

    def each_contig(filename : Path | String)
      filename = Path.new(filename)
      File.open(filename) do |file|
        file = Compress::Gzip::Reader.new(file) if filename.extension == ".gz"

        name = nil
        sequence = IO::Memory.new

        file.each_line(chomp = true) do |line|
          if line.starts_with?(">")
            yield name, sequence unless name.nil?
            name = line[1..-1]
            sequence = IO::Memory.new
          else
            if line.ascii_only?
              sequence << line
            else
              raise <<-ERROR
                [wgsim] Non-ASCII characters in FASTA file: #{filename}
                  #{name}
                  #{sequence}
                ERROR
            end
          end
        end

        file.close if filename.extension == ".gz"
        yield name, sequence unless name.nil?
      end
    end

    def normalize_sequence(sequence : IO::Memory | String) : Slice(UInt8)
      sequence.to_slice.map do |c|
        case c
        when 65u8, 97u8  then 65u8 # A
        when 67u8, 99u8  then 67u8 # C
        when 71u8, 103u8 then 71u8 # G
        when 84u8, 116u8 then 84u8 # T
        when 78u8, 110u8 then 78u8 # N
        else
          STDERR.puts "[wgsim] '#{c.chr}' is replaced with 'N'"
          78u8 # N
        end
      end
    end
  end
end
