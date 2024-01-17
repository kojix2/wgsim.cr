# wgsim.cr

[![build](https://github.com/kojix2/wgsim.cr/actions/workflows/build.yml/badge.svg)](https://github.com/kojix2/wgsim.cr/actions/workflows/build.yml)

Trying to re-implement and add functionality to [wgsim](https://github.com/lh3/wgsim) in Crystal.

Please note that this project has been created for personal learning and experimental purposes and is not intended for practical use.

## Installation

GitHub Releases:

From source:

```sh
git clone https://github.com/kojix2/wgsim.cr
cd wgsim.cr
shards build --release -Dpreview_mt src/wgsim.cr
```

## Usage

```
  Program: wgsim (Crystal implementation of wgsim)
  Version: 0.0.0.alpha
    mut          mutate the reference
    seq          generate the reads
    help         show this help message
    version      show version number
```

## NOTE

- The tool provides two simulation classes: `MutationSimulator` and `SequenceSimulator`. (You may also want to add a `SelectionSimulator`.)
- The important point is to generate all the genomes that the cell has in the Fasta file. If the chromosome copy number is increased by extrachromosomal DNA, for example, actually add such records to FASTA.
  
## Contributing

1. Fork it (<https://github.com/your-github-user/wgsim/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
