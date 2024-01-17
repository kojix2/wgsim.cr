# wgsim.cr

[![build](https://github.com/kojix2/wgsim.cr/actions/workflows/build.yml/badge.svg)](https://github.com/kojix2/wgsim.cr/actions/workflows/build.yml)

Trying to re-implement and add functionality to [wgsim](https://github.com/lh3/wgsim) in Crystal.

:black_cat: Please note that this project has been created for personal learning and experimental purposes and is not intended for practical use.

## Installation

[GitHub Releases](https://github.com/kojix2/wgsim.cr/releases/latest)

From source:

```sh
git clone https://github.com/kojix2/wgsim.cr
cd wgsim.cr
shards build --release -Dpreview_mt src/wgsim.cr
```

## Usage

```
  Program: wgsim (Crystal implementation of wgsim)
  Version: 0.0.1.alpha
    mut          mutate the reference
    seq          generate the reads
    version      show version number
```

```
  Usage: wgsim mut [options] <in.ref.fa>

    -r FLOAT     rate of mutations [0.001]
    -R FLOAT     fraction of indels [0.15]
    -X FLOAT     probability an indel is extended [0.3]
    -S UINT64    seed for random generator
    -t INT       Number of threads [4]
    --help       show this help message
```

```
  Usage: wgsim seq [options] <in.ref.fa> <out.read1.fq> <out.read2.fq>

    -e FLOAT     base error rate [0.02]
    -d INT       outer distance between the two ends [500]
    -s INT       standard deviation [50]
    -D FLOAT     average sequencing depth [10.0]
    -1 INT       length of the first read [70]
    -2 INT       length of the second read [70]
    -A FLOAT     Discard reads over FLOAT% ambiguous bases [0.05]
    -S UINT64    seed for random generator
    -t INT       Number of threads [4]
    --help       show this help message
```

## NOTE

- The tool provides two simulation classes: `MutationSimulator` and `SequenceSimulator`. (You may also want to add a `SelectionSimulator`.)
- The key point is to include the complete DNA sequence of the cell's genome in the Fasta file. In the case of diploid cells, two Fasta records should be added for each pair of homologous chromosomes. When there is an increase in chromosome copy number due to extrachromosomal DNA, additional records must be included in the Fasta file to reflect this amplification. If a chromosome undergoes inversion or fusion, the Fasta file should contain a record that accurately represents these changes. This means that the genome should not be represented in any compressed form on the computer. Consequently, there will be as many `UInt8` or `RefBase` structures as there are nucleotides. While this approach may reduce processing speed and increase disk and memory usage, it helps to avoid many complications.
- [wgsimのコードを眺める [JA]](https://qiita.com/kojix2/items/35318fbefe0e2ea9fca1)
  
## Contributing

1. Fork it (<https://github.com/your-github-user/wgsim/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
