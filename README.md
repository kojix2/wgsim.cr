# wgsim.cr

[![build](https://github.com/kojix2/wgsim.cr/actions/workflows/build.yml/badge.svg)](https://github.com/kojix2/wgsim.cr/actions/workflows/build.yml)

Reimplement [wgsim](https://github.com/lh3/wgsim) in Crystal and add extra features.

:yarn: :black_cat: Please note that this project is being created for personal study and experimental purposes and is not currently provided for practical purposes.

- `mut` : Adding mutations to the reference genome
  - SNPs
  - Insertion (any length)
  - Deletion (any length)
  - Fasta Output
- `seq` : Simulation of short lead sequencing
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
shards build --release -Dpreview_mt src/wgsim.cr
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
Version: 0.0.4.alpha
Source:  https://github.com/kojix2/wgsim.cr

    mut                              Add mutations to reference sequences
    seq                              Simulate pair-end sequencing
    gen                              Generate random reference fasta

    --debug                          Show backtrace on error
    -v, --version                    Show version
    -h, --help                       Show this help
```

```
About: Add mutations to reference sequences
Usage: wgsim mut [options] -f <in.ref.fa>

    -f, --file FILE                  Input file for the reference sequence (required)
    -o, --output FILE                Output file for the mutated sequence (required)
    -m, --mutation FILE              Output file for the mutations (required)
    -s, --sub-rate FLOAT             Rate of base substitutions [0.001]
    -i, --ins-rate FLOAT             Rate of insertions [0.0001]
    -d, --del-rate FLOAT             Rate of deletions [0.0001]
    -I, --ins-ext-prob FLOAT         Probability an insertion is extended [0.3]
    -D, --del-ext-prob FLOAT         Probability a deletion is extended [0.3]
    -p, --ploidy UINT8               Number of chromosome copies in output fasta [2]
    -S, --seed UINT64                Seed for random generator
    --debug                          Show backtrace on error
    -h, --help                       Show this help
```

```
About: Simulate pair-end sequencing
Usage: wgsim seq [options] -f <in.ref.fa> -1 <out.read1.fq> -2 <out.read2.fq>

    -f, --file FILE                  Input file for the reference sequence (required)
    -1, --output1 FILE               Output file for the first read (required)
    -2, --output2 FILE               Output file for the second read (required)
    -e, --error-rate FLOAT           Base error rate [0.01]
    -d, --distance INT               Outer distance between the two ends [500]
    -s, --std-dev FLOAT              Standard deviation of the insert size [50]
    -D, --depth FLOAT                Average sequencing depth [10.0]
    -L, --size-left INT              Length of the first read [100]
    -R, --size-right INT             Length of the second read [100]
    -A, --ambiguous-ratio FLOAT      Discard if the fraction of N(ambiguous) bases higher than FLOAT [0.05]
    -S, --seed UINT64                Seed for random generator
    --debug                          Show backtrace on error
    -h, --help                       Show this help
```

```
About: Generate random reference fasta
Usage: wgsim gen [options]

    -l, --length INT                 Length of the reference sequence ["1000,700"]
    -s, --seed UINT64                Seed for random generator
    --debug                          Show backtrace on error
    -h, --help                       Show this help
```

### Idea Notes

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

## Development

Dependencies:

- [kojix2/nworkers.cr](https://github.com/kojix2/nworkers.cr) - Set the number of worker threads at runtime.
- [kojix2/randn.cr](https://github.com/kojix2/randn.cr) - Normal random number generator.
- [kojix2/fastx.cr](https://github.com/kojix2/fastx.cr) - Fasta file reader.
  
## Contributing

1. Fork it (<https://github.com/kojix2/wgsim/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
