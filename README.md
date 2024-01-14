# wgsim.cr

Trying to re-implement and add functionality to [wgsim](https://github.com/lh3/wgsim) in Crystal.
Please note that this project is experimental and is not being made available for practical purposes.

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
  Program: wgsim (short read simulator)
  Version: 0.1.0
  Usage:   wgsim [options] <in.ref.fa> <out.read1.fq> <out.read2.fq>
  Options:
    -e FLOAT     base error rate [0.02]
    -d INT       outer distance between the two ends [500]
    -s INT       standard deviation [50]
    -N INT64     number of read pairs [1000000]
    -1 INT       length of the first read [70]
    -2 INT       length of the second read [70]
    -r FLOAT     rate of mutations [0.001]
    -R FLOAT     fraction of indels [0.15]
    -X FLOAT     probability an indel is extended [0.3]
    -S UINT64    seed for random generator []
    -A FLOAT     Discard reads over FLOAT% ambiguous bases [0.05]
    -t INT       Number of threads [4]
    --help       show this help message
    --version    show version number
```

## Development

## Contributing

1. Fork it (<https://github.com/your-github-user/wgsim/fork>)
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
