module Wgsim
  class SequenceSimulator
    delegate _rand, rand_norm, rand_bool, to: @random
    getter distance : Int32
    getter std_deviation : Int32
    getter total_pairs : Int64
    getter size_left : Int32
    getter size_right : Int32
    getter error_rate : Float64
    getter max_ambiguous_ratio : Float64

    def initialize(
      @total_pairs,
      @distance,
      @std_deviation,
      @size_left,
      @size_right,
      @error_rate,
      @max_ambiguous_ratio,
      @random = Rand.new
    )
    end

    def run(contig_sequences, total_seq_length, mutation_simulator)
      contig_sequences.each do |name, sequence|
        contig_length = sequence.size

        if contig_length < (min_len = distance + 3 * std_deviation)
          STDERR.puts "[wgsim] skip sequence '#{name}' as it is shorter than #{min_len} bp"
          next
        end

        n_pairs = (total_pairs.to_f * contig_length / total_seq_length).ceil

        seq1 = mutation_simulator.simulate_mutations(name, sequence)
        seq2 = mutation_simulator.simulate_mutations(name, sequence)
        # wgsim_print_mutref

        pair_index = 0
        while pair_index < n_pairs
          pair_index % 10000 == 0 && puts "[wgsim] #{name} #{pair_index}/#{n_pairs}"

          insert_size = random_insert_size
          position = random_position(contig_length, insert_size)

          # should not happen
          position < 0 || position > contig_length || position + insert_size - 1 < contig_length ||
            raise "Invalid position or insert size: " \
                  "position=#{position}, insert_size=#{insert_size}, contig_length=#{contig_length}"

          target_seq = rand_bool ? seq1 : seq2

          # flip or not
          flip = rand_bool

          read1_sequence, read2_sequence = generate_pair_sequence(target_seq, position, insert_size, flip)
          next if read1_sequence.count('N') / read1_sequence.size > max_ambiguous_ratio ||
                  read2_sequence.count('N') / read2_sequence.size > max_ambiguous_ratio

          # generate sequence error
          read1_sequence = generate_sequencing_error(read1_sequence)
          read2_sequence = generate_sequencing_error(read2_sequence)

          yield(
            fasta_record(name.split[0], pair_index, position, insert_size, 0, read1_sequence),
            fasta_record(name.split[0], pair_index, position, insert_size, 1, read2_sequence)
          )

          pair_index += 1
        end
      end
    end

    def generate_pair_sequence(target_seq, position, insert_size, flip) : Tuple(Slice(UInt8), Slice(UInt8))
      if flip
        read1 = target_seq[position...(position + size_left)].map { |b| b.nucleotide }
        read2 = reverse_complement(target_seq[(position + insert_size - size_right)...(position + insert_size)])
      else
        read1 = reverse_complement(target_seq[(position + insert_size - size_left)...(position + insert_size)])
        read2 = target_seq[position...(position + size_right)].map { |b| b.nucleotide }
      end

      {read1, read2}
    end

    def fasta_record(name, pair_index, position, insert_size, read_index, sequence : Slice(UInt8)) : String
      sequence = String.new(sequence)
      String.build do |str|
        str << ">#{name}_#{position}_#{insert_size}:#{pair_index}/#{read_index + 1}" << "\n"
        str << sequence << "\n"
        str << "+" << "\n"
        str << "2" * [size_left, size_right][read_index] << "\n"
      end
    end

    def generate_sequencing_error(sequence : Slice(UInt8)) : Slice(UInt8)
      valid_nucleotides = [65u8, 67u8, 71u8, 84u8] # A, C, G, T

      sequence.map do |b|
        case b
        when 78u8 then b            # N
        when 65u8, 67u8, 71u8, 84u8 # A, C, G, T
          if _rand < error_rate
            other_nucleotides = valid_nucleotides - [b]
            other_nucleotides[_rand(3)]
          else
            b
          end
        else
          raise "Invalid nucleotide: #{b}"
        end
      end
    end

    def reverse_complement(sequence : Slice(RefBase)) : Slice(UInt8)
      complements = {
        65u8 => 84u8, # A -> T
        67u8 => 71u8, # C -> G
        71u8 => 67u8, # G -> C
        84u8 => 65u8, # T -> A
        78u8 => 78u8, # N -> N
      }

      sequence.map do |b|
        complements.fetch(b.nucleotide) { raise "Invalid nucleotide: #{b.nucleotide}" }
      end.reverse!
    end

    def random_insert_size
      [rand_norm(distance, std_deviation).to_i, size_left, size_right].max
    end

    def random_position(contig_length : Int, insert_size : Int)
      _rand(contig_length - insert_size + 1)
    end
  end
end
