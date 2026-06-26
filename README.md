# wgsim.cr

[![build](https://github.com/kojix2/wgsim.cr/actions/workflows/build.yml/badge.svg)](https://github.com/kojix2/wgsim.cr/actions/workflows/build.yml)

Reimplement [wgsim](https://github.com/lh3/wgsim) in Crystal and add extra features.

:yarn: :black_cat: Please note that this project is being created for personal study and experimental purposes and is not currently provided for practical purposes.

- `mut` : Adding mutations to the reference genome
  - SNPs
  - Insertion (any length)
  - Deletion (any length)
  - Fasta Output
- `seq` : Simulation of short-read sequencing
  - Uniform substitution sequencing errors
  - Fastq Output
- `gen` : Generate a random genome
  - Random genome generation
  - Fasta Output

## Installation

[GitHub Releases](https://github.com/kojix2/wgsim.cr/releases/latest)

### Compiling from source code

```sh
git clone https://github.com/kojix2/wgsim.cr
cd wgsim.cr
shards build --release
```

### Homebrew

[![wgsim (macos)](https://github.com/kojix2/homebrew-brew/actions/workflows/wgsim-macos.yml/badge.svg)](https://github.com/kojix2/homebrew-brew/actions/workflows/wgsim-macos.yml)
[![wgsim (ubuntu)](https://github.com/kojix2/homebrew-brew/actions/workflows/wgsim-ubuntu.yml/badge.svg)](https://github.com/kojix2/homebrew-brew/actions/workflows/wgsim-ubuntu.yml)

```
brew install kojix2/brew/wgsim
```

## Usage

```
Program: wgsim (Crystal implementation of wgsim)
Version: 0.0.9.alpha
Source:  https://github.com/kojix2/wgsim.cr

    mut                              Add biological mutations to reference sequences
    seq                              Simulate paired-end sequencing reads
    gen                              Generate random reference FASTA

    --debug                          Show backtrace on error
    -v, --version                    Show version
    -h, --help                       Show this help
```

```
About: Add biological mutations to reference sequences
Usage: wgsim mut [options] -r <in.ref.fa> -o <out.fa> -l <out.tsv>

    -r, --reference FILE             Input reference FASTA (required)
    -o, --mutated-fasta FILE         Output mutated FASTA (required)
    -l, --mutation-log FILE          Output mutation event log TSV (required)
    -s, --sub-rate FLOAT             Per-base substitution probability [0.001]
    -i, --ins-rate FLOAT             Per-base insertion probability [0.0001]
    -d, --del-rate FLOAT             Per-base deletion-start probability [0.0001]
    -I, --ins-extend FLOAT           Probability of extending an insertion by one base [0.3]
    -D, --del-extend FLOAT           Probability of extending an open deletion by one base [0.3]
    -p, --ploidy UINT8               Number of mutated chromosome copies per input sequence [2]
    -S, --seed UINT64                Random seed
    --debug                          Show backtrace on error
    -h, --help                       Show this help
```

```
About: Simulate paired-end sequencing reads
Usage: wgsim seq [options] -r <in.ref.fa> -1 <out.read1.fq> -2 <out.read2.fq>

    -r, --reference FILE             Input reference FASTA (required)
    -1, --read1-fastq FILE           Output FASTQ for read 1 (required)
    -2, --read2-fastq FILE           Output FASTQ for read 2 (required)
    -e, --error-rate FLOAT           Per-base sequencing error probability [0.01]
    -m, --mean-insert INT            Mean insert size [500]
    -s, --insert-sd FLOAT            Insert size standard deviation [50]
    -D, --depth FLOAT                Average sequencing depth [10.0]
    -L, --read1-len INT              Read 1 length [100]
    -R, --read2-len INT              Read 2 length [100]
    -A, --max-n-ratio FLOAT          Discard a read pair if either read has a higher N fraction [0.05]
    -S, --seed UINT64                Random seed
    --debug                          Show backtrace on error
    -h, --help                       Show this help
```

```
About: Generate random reference FASTA
Usage: wgsim gen [options]

    -l, --chromosome-lengths INT     Comma-separated chromosome lengths ["1000,500"]
    -S, --seed UINT64                Random seed
    --debug                          Show backtrace on error
    -h, --help                       Show this help
```

## Idea Notes

- Somatic Mutations
  - Broad Representation: Include `SNVs`, `indels`, `large insertions`, `large deletions`, and `translocations`.
  - Complete DNA Sequence in Fasta: Include the entire genome in the Fasta file.

- Haplotypes
  - Ploidy: Include as many Fasta records as there are homologous chromosomes, depending on the cell's ploidy.

- Structural Variations
  - Inversion and Fusion: Accurately represent structural variations like inversions and fusions in the Fasta file.

- Local Amplifications
  - Extrachromosomal DNA: Include additional records for increased chromosome copy number due to extrachromosomal DNA.

- Non-Compressed Genome Representation
  - Data Structures: Use `UInt8` or `RefBase` structures for each nucleotide to keep things simple.

- Addressing Heterogeneity
  - Fasta File per Cell Type: Each cell type has one Fasta file.
  - Cell Type Proportions: Provide the proportion of each cell type.

- VCF files have a dual purpose:
  - They act as snapshots of the current state by capturing differences from the reference genome.
  - They are presumed detailed records of genetic variations.

- We attempt to infer mutations by observing individual genomes, but we can never fully reconstruct the events.
  - In simulations, however, we can have a complete list of mutation events.

- [wgsimのコードを眺める [JA]](https://qiita.com/kojix2/items/35318fbefe0e2ea9fca1)

## Reading the Code

The code is intentionally organized around biological concepts rather than
around terse implementation tricks.

- `src/wgsim/dna.cr`
  - Defines byte-level DNA bases, IUPAC ambiguity normalization, substitution
    choices, and reverse complements.
- `src/wgsim/mutate/mutation_simulator.cr`
  - Walks through a reference sequence one base at a time, samples biological
    mutation types, and records the complete mutation history.
- `src/wgsim/mutate/mutation_event_builder.cr`
  - Converts simulated substitutions, insertions, and deletions into explicit
    event-log records.
- `src/wgsim/sequencing/read_pair_simulator.cr`
  - Samples DNA fragments, chooses read orientation, extracts paired-end reads,
    filters high-`N` reads, and then adds sequencing errors.
- `src/wgsim/sequencing/error_model.cr`
  - Models sequencing errors separately from biological mutations.

Two separations are especially important when reading or modifying the code:

- Biological mutations happen in `mut`, before reads are generated.
- Sequencing errors happen in `seq`, after reads are sampled from the input
  FASTA.

## Development

Dependencies:

- [kojix2/randn.cr](https://github.com/kojix2/randn.cr) - Normal random number generator.
- [kojix2/fastx.cr](https://github.com/kojix2/fastx.cr) - FASTA/FASTQ reader and writer.

Multithreaded execution is not implemented. Do not build with `-Dpreview_mt` expecting parallel `mut`, `seq`, or `gen` processing.

## Contributing

1. Fork it (<https://github.com/kojix2/wgsim/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
