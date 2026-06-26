# wgsim.cr Manual

`wgsim.cr` is a Crystal implementation inspired by `wgsim`. It provides three command-line workflows for small genome simulation tasks:

- `gen`: generate random reference FASTA sequences
- `mut`: add substitutions, insertions, and deletions to reference FASTA sequences
- `seq`: simulate paired-end short-read sequencing and write FASTQ files

Biological mutations are introduced only by `mut`. The `seq` command does not add biological mutations; it only samples reads from the input FASTA and applies sequencing errors.

This project is experimental and intended for study and development use.

Each command writes its effective parameters to standard error before doing
work. Progress and warnings are also written to standard error, while FASTA and
FASTQ data remain on the configured output streams/files.

## Installation

Download a binary from the GitHub releases page, or build from source:

```sh
git clone https://github.com/kojix2/wgsim.cr
cd wgsim.cr
shards build --release
```

The compiled executable is usually written to `bin/wgsim`.

On systems with the project Homebrew tap:

```sh
brew install kojix2/brew/wgsim
```

## Basic Usage

```sh
wgsim <command> [options]
```

Available commands:

```text
mut    Add mutations to reference sequences
seq    Simulate paired-end sequencing
gen    Generate random reference FASTA
```

General options:

```text
--debug        Show a backtrace when an error occurs
-v, --version  Show the version
-h, --help     Show help
```

Use command-specific help for the exact options supported by your installed build:

```sh
wgsim mut --help
wgsim seq --help
wgsim gen --help
```

## Generate a Random Reference

The `gen` command writes random FASTA records to standard output.

```sh
wgsim gen > reference.fa
```

Generate two chromosomes with specified lengths:

```sh
wgsim gen --chromosome-lengths 100000,50000 --seed 42 > reference.fa
```

Options:

| Option | Description | Default |
| --- | --- | --- |
| `-l, --chromosome-lengths INT` | Comma-separated chromosome lengths | `1000,500` |
| `-S, --seed UINT64` | Random seed | random |
| `--debug` | Show a backtrace on error | off |
| `-h, --help` | Show command help | |

Output FASTA headers are generated as `chr0`, `chr1`, and so on, with length and seed metadata in the header line.

Parameter summary lines are written to standard error before the FASTA records,
so redirecting standard output is enough to capture only FASTA data.

## Add Mutations

The `mut` command reads a reference FASTA file, writes a mutated FASTA file, and writes a tab-separated mutation event log.

```sh
wgsim mut \
  --reference reference.fa \
  --mutated-fasta mutated.fa \
  --mutation-log mutations.tsv \
  --seed 42
```

By default, `mut` emits two chromosome copies for each input sequence. Use `--ploidy 1` for one output record per input record.

Mutation probabilities are applied independently at each non-`N` reference base. Lowercase `a/c/g/t/n` bases are normalized to uppercase before mutation. IUPAC ambiguous bases such as `R`, `Y`, `K`, and `W` are normalized to `N` and are not mutated.

Options:

| Option | Description | Default |
| --- | --- | --- |
| `-r, --reference FILE` | Input reference FASTA file | required |
| `-o, --mutated-fasta FILE` | Output mutated FASTA file | required |
| `-l, --mutation-log FILE` | Output mutation event log TSV | required |
| `-s, --sub-rate FLOAT` | Per-base substitution probability | `0.001` |
| `-i, --ins-rate FLOAT` | Per-base insertion probability | `0.0001` |
| `-d, --del-rate FLOAT` | Per-base deletion-start probability | `0.0001` |
| `-I, --ins-extend FLOAT` | Probability of extending an insertion by one base | `0.3` |
| `-D, --del-extend FLOAT` | Probability of extending an open deletion by one base | `0.3` |
| `-p, --ploidy UINT8` | Number of mutated chromosome copies per input sequence | `2` |
| `-S, --seed UINT64` | Random seed | random |
| `--debug` | Show a backtrace on error | off |
| `-h, --help` | Show command help | |

Mutation event log columns:

```text
sequence_name  position  ref  alt  mutation_type
```

Positions are 1-based. Insertions record the reference base in `ref` and the reference base plus inserted bases in `alt`. Deletions use `.` as `alt`.

Example:

```text
chr0_1  120  A   G      SUBSTITUTE
chr0_1  305  T   TCAA   INSERT
chr0_1  410  AC  .      DELETE
```

## Simulate Paired-End Sequencing

The `seq` command reads a reference FASTA file and writes two FASTQ files for paired-end reads.

`seq` is a read simulator, not a genome mutation simulator. To simulate biological variants, run `mut` first and then pass the mutated FASTA to `seq`. The only per-base change introduced by `seq` is a uniform sequencing substitution error controlled by `--error-rate`.

```sh
wgsim seq \
  --reference mutated.fa \
  --read1-fastq reads_1.fq \
  --read2-fastq reads_2.fq \
  --depth 20 \
  --read1-len 150 \
  --read2-len 150 \
  --seed 42
```

Options:

| Option | Description | Default |
| --- | --- | --- |
| `-r, --reference FILE` | Input reference FASTA file | required |
| `-1, --read1-fastq FILE` | Output FASTQ file for read 1 | required |
| `-2, --read2-fastq FILE` | Output FASTQ file for read 2 | required |
| `-e, --error-rate FLOAT` | Per-base sequencing error probability | `0.01` |
| `-m, --mean-insert INT` | Mean insert size | `500` |
| `-s, --insert-sd FLOAT` | Insert size standard deviation | `50` |
| `-D, --depth FLOAT` | Average sequencing depth | `10.0` |
| `-L, --read1-len INT` | Read 1 length | `100` |
| `-R, --read2-len INT` | Read 2 length | `100` |
| `-A, --max-n-ratio FLOAT` | Discard a read pair if either read has a higher `N` fraction | `0.05` |
| `-S, --seed UINT64` | Random seed | random |
| `--debug` | Show a backtrace on error | off |
| `-h, --help` | Show command help | |

Read-pair count is estimated from contig length, average depth, and read lengths:

```text
number_of_pairs = contig_length * depth / (read1_length + read2_length)
```

The command prints the parameter summary and progress messages to standard error while generating reads. FASTQ quality is currently uniform across each read and is derived from the selected error rate.

Lowercase `a/c/g/t/n` input bases are normalized to uppercase before read generation. IUPAC ambiguous bases are normalized to `N`; the `--max-n-ratio` filter uses this normalized `N` count.

FASTA input files ending in `.gz` are read as gzip-compressed input. Mutated FASTA and read FASTQ outputs ending in `.gz` are written as gzip-compressed output. The `gen` command writes to standard output; pipe it through `gzip` when compressed random-reference output is needed.

## Reproducibility

Pass `--seed` to make random generation reproducible for a given command and option set:

```sh
wgsim gen --chromosome-lengths 10000 --seed 1 > reference.fa
wgsim mut --reference reference.fa --mutated-fasta mutated.fa --mutation-log mutations.tsv --seed 2
wgsim seq --reference mutated.fa --read1-fastq reads_1.fq --read2-fastq reads_2.fq --seed 3
```

Use different seeds for independent simulation stages when you want each stage to be reproducible but statistically separate.

## Common Workflow

```sh
# 1. Generate a reference.
wgsim gen --chromosome-lengths 100000,100000 --seed 1 > reference.fa

# 2. Add mutations.
wgsim mut \
  --reference reference.fa \
  --mutated-fasta mutated.fa \
  --mutation-log mutations.tsv \
  --sub-rate 0.001 \
  --ins-rate 0.0001 \
  --del-rate 0.0001 \
  --seed 2

# 3. Simulate paired-end reads.
wgsim seq \
  --reference mutated.fa \
  --read1-fastq reads_1.fq \
  --read2-fastq reads_2.fq \
  --depth 30 \
  --read1-len 150 \
  --read2-len 150 \
  --seed 3
```

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

## Design Notes and Future Ideas

- Somatic mutations
  - Broad representation: include `SNVs`, `indels`, large insertions, large
    deletions, and translocations.
  - Complete DNA sequence in FASTA: include the entire genome in the FASTA file.
- Haplotypes
  - Ploidy: include as many FASTA records as there are homologous chromosomes,
    depending on the cell's ploidy.
- Structural variations
  - Inversion and fusion: accurately represent structural variations like
    inversions and fusions in the FASTA file.
- Local amplifications
  - Extrachromosomal DNA: include additional records for increased chromosome
    copy number due to extrachromosomal DNA.
- Non-compressed genome representation
  - Data structures: use `UInt8` or `ReferenceBase` structures for each
    nucleotide to keep the model simple.
- Addressing heterogeneity
  - FASTA file per cell type: each cell type has one FASTA file.
  - Cell type proportions: provide the proportion of each cell type.
- VCF files have a dual purpose:
  - They act as snapshots of the current state by capturing differences from
    the reference genome.
  - They are presumed detailed records of genetic variations.
- We attempt to infer mutations by observing individual genomes, but we can
  never fully reconstruct the events.
  - In simulations, however, we can have a complete list of mutation events.

## Notes and Limitations

- `mut` currently records mutation events in a simple tab-separated format, not VCF.
- `seq` does not add biological mutations. Use `mut` before `seq` when variants are required.
- Sequencing errors are modeled as uniform base substitutions.
- Lowercase `a/c/g/t/n` bases are accepted and normalized to uppercase. Other IUPAC ambiguous bases are normalized to `N`.
- FASTA input and FASTA/FASTQ output are handled through `fastx.cr`; path-based readers/writers auto-detect gzip from `.gz`.
- Contigs shorter than the configured read length are skipped by `seq`.
- All commands print their effective parameters to standard error for reproducibility.
- Multithreaded processing is not implemented; builds do not need `-Dpreview_mt`.
- Numeric options are validated. Rates and probabilities must be in valid ranges, read lengths and chromosome lengths must be positive, and `mut` rates must sum to `1.0` or less.
- The tool is experimental and not intended as a validated production simulator.
