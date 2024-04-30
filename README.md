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
  Version: 0.0.1.alpha
    mut          mutate the reference
    seq          generate the reads
```

```
Usage: wgsim mut [options] <in.ref.fa>

    -s, --substitution-rate FLOAT    rate of base substitutions [0.001]
    -i, --insertion-rate FLOAT       rate of insertions [0.0001]
    -d, --deletion-rate FLOAT        rate of deletions [0.0001]
    -I, --ins-ext-prob FLOAT         probability an insertion is extended [0.3]
    -D, --del-ext-prob FLOAT         probability a deletion is extended [0.3]
    -p, --ploidy UINT8               ploidy [2]
    -S, --seed UINT64                seed for random generator
```

```
Usage: wgsim seq [options] <in.ref.fa> <out.read1.fq> <out.read2.fq>

    -e, --error-rate FLOAT           base error rate [0.02]
    -d, --distance INT               outer distance between the two ends [500]
    -s, --std-dev FLOAT              standard deviation [50]
    -D, --depth FLOAT                average sequencing depth [10.0]
    -1, --size-left INT              length of the first read [70]
    -2, --size-right INT             length of the second read [70]
    -A, --ambiguous-ratio FLOAT      Discard reads over FLOAT% ambiguous bases [0.05]
    -S, --seed UINT64                seed for random generator
```

## NOTE

- The key point is to include the complete DNA sequence of the cell's genome in the Fasta file. In the case of diploid cells, two Fasta records should be added for each pair of homologous chromosomes. When there is an increase in chromosome copy number due to extrachromosomal DNA, additional records must be included in the Fasta file to reflect this amplification. If a chromosome undergoes inversion or fusion, the Fasta file should contain a record that accurately represents these changes. This means that the genome should not be represented in any compressed form on the computer. Consequently, there will be as many `UInt8` or `RefBase` structures as there are nucleotides. While this approach may reduce processing speed and increase disk and memory usage, it helps to avoid many complications.
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
