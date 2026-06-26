# wgsim.cr マニュアル

`wgsim.cr` は `wgsim` に着想を得た Crystal 実装です。小規模なゲノムシミュレーション向けに、次の 3 つのコマンドを提供します。

- `gen`: ランダムな参照 FASTA 配列を生成する
- `mut`: 参照 FASTA 配列に置換、挿入、欠失を加える
- `seq`: ペアエンド短鎖リードをシミュレートし、FASTQ ファイルを書き出す

生物学的な変異を導入するのは `mut` だけです。`seq` は入力 FASTA からリードをサンプリングし、シーケンスエラーを加えるだけで、生物学的変異は追加しません。

このプロジェクトは実験的なもので、学習と開発を目的としています。

各コマンドは、処理を始める前に有効な実行パラメータを標準エラーへ出力します。進捗や警告も標準エラーへ出力され、FASTA/FASTQ データは指定された出力先または標準出力にだけ書き出されます。

## インストール

GitHub Releases からバイナリを取得するか、ソースコードからビルドします。

```sh
git clone https://github.com/kojix2/wgsim.cr
cd wgsim.cr
shards build --release
```

通常、ビルドされた実行ファイルは `bin/wgsim` に作成されます。

Homebrew tap を使える環境では次のようにインストールできます。

```sh
brew install kojix2/brew/wgsim
```

## 基本的な使い方

```sh
wgsim <command> [options]
```

利用できるコマンド:

```text
mut    参照配列に変異を加える
seq    ペアエンドシーケンスをシミュレートする
gen    ランダムな参照 FASTA を生成する
```

共通オプション:

```text
--debug        エラー時にバックトレースを表示する
-v, --version  バージョンを表示する
-h, --help     ヘルプを表示する
```

インストール済みビルドで利用できる正確なオプションは、各コマンドのヘルプで確認してください。

```sh
wgsim mut --help
wgsim seq --help
wgsim gen --help
```

## ランダムな参照配列を生成する

`gen` コマンドは、ランダムな FASTA レコードを標準出力へ書き出します。

```sh
wgsim gen > reference.fa
```

長さを指定して 2 本の染色体を生成する例:

```sh
wgsim gen --chromosome-lengths 100000,50000 --seed 42 > reference.fa
```

オプション:

| オプション | 説明 | デフォルト |
| --- | --- | --- |
| `-l, --chromosome-lengths INT` | カンマ区切りの染色体長 | `1000,500` |
| `-S, --seed UINT64` | 乱数シード | ランダム |
| `--debug` | エラー時にバックトレースを表示する | オフ |
| `-h, --help` | コマンドヘルプを表示する | |

出力 FASTA のヘッダーは `chr0`, `chr1` のように生成され、ヘッダー行には長さとシードの情報も含まれます。

FASTA レコードの前に、パラメータ概要が標準エラーへ出力されます。そのため、標準出力をリダイレクトすれば FASTA データだけを保存できます。

## 変異を加える

`mut` コマンドは参照 FASTA ファイルを読み込み、変異後の FASTA ファイルと、タブ区切りの変異イベントログを書き出します。

```sh
wgsim mut \
  --reference reference.fa \
  --mutated-fasta mutated.fa \
  --mutation-log mutations.tsv \
  --seed 42
```

デフォルトでは、入力配列ごとに 2 コピーの染色体を出力します。入力 1 レコードにつき出力 1 レコードにしたい場合は `--ploidy 1` を指定します。

変異確率は、`N` 以外の参照塩基ごとに独立に適用されます。小文字の `a/c/g/t/n` は、変異処理の前に大文字へ正規化されます。`R`, `Y`, `K`, `W` などの IUPAC 曖昧塩基は `N` に正規化され、変異対象から外れます。

オプション:

| オプション | 説明 | デフォルト |
| --- | --- | --- |
| `-r, --reference FILE` | 入力参照 FASTA ファイル | 必須 |
| `-o, --mutated-fasta FILE` | 変異後 FASTA の出力ファイル | 必須 |
| `-l, --mutation-log FILE` | 変異イベントログ TSV の出力ファイル | 必須 |
| `-s, --sub-rate FLOAT` | 塩基ごとの置換確率 | `0.001` |
| `-i, --ins-rate FLOAT` | 塩基ごとの挿入確率 | `0.0001` |
| `-d, --del-rate FLOAT` | 塩基ごとの欠失開始確率 | `0.0001` |
| `-I, --ins-extend FLOAT` | 挿入が 1 塩基延長される確率 | `0.3` |
| `-D, --del-extend FLOAT` | 開いている欠失が 1 塩基延長される確率 | `0.3` |
| `-p, --ploidy UINT8` | 入力配列ごとの変異後染色体コピー数 | `2` |
| `-S, --seed UINT64` | 乱数シード | ランダム |
| `--debug` | エラー時にバックトレースを表示する | オフ |
| `-h, --help` | コマンドヘルプを表示する | |

変異イベントログの列:

```text
sequence_name  position  ref  alt  mutation_type
```

位置は 1-based です。挿入では `ref` に参照塩基、`alt` に参照塩基と挿入塩基を連結した配列が記録されます。欠失では `alt` が `.` になります。

例:

```text
chr0_1  120  A   G      SUBSTITUTE
chr0_1  305  T   TCAA   INSERT
chr0_1  410  AC  .      DELETE
```

## ペアエンドシーケンスをシミュレートする

`seq` コマンドは参照 FASTA ファイルを読み込み、ペアエンドリード用に 2 つの FASTQ ファイルを書き出します。

`seq` はリードシミュレータであり、ゲノム変異シミュレータではありません。生物学的変異を含むリードを作りたい場合は、先に `mut` で変異後 FASTA を作成し、それを `seq` に渡します。`seq` が塩基ごとに加える変化は、`--error-rate` で制御される一様なシーケンス置換エラーだけです。

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

オプション:

| オプション | 説明 | デフォルト |
| --- | --- | --- |
| `-r, --reference FILE` | 入力参照 FASTA ファイル | 必須 |
| `-1, --read1-fastq FILE` | read 1 の出力 FASTQ ファイル | 必須 |
| `-2, --read2-fastq FILE` | read 2 の出力 FASTQ ファイル | 必須 |
| `-e, --error-rate FLOAT` | 塩基ごとのシーケンスエラー確率 | `0.01` |
| `-m, --mean-insert INT` | 平均インサートサイズ | `500` |
| `-s, --insert-sd FLOAT` | インサートサイズの標準偏差 | `50` |
| `-D, --depth FLOAT` | 平均シーケンス深度 | `10.0` |
| `-L, --read1-len INT` | read 1 の長さ | `100` |
| `-R, --read2-len INT` | read 2 の長さ | `100` |
| `-A, --max-n-ratio FLOAT` | どちらかのリードの `N` 割合がこの値より高いリードペアを破棄する | `0.05` |
| `-S, --seed UINT64` | 乱数シード | ランダム |
| `--debug` | エラー時にバックトレースを表示する | オフ |
| `-h, --help` | コマンドヘルプを表示する | |

リードペア数は、コンティグ長、平均深度、リード長から概算されます。

```text
number_of_pairs = contig_length * depth / (read1_length + read2_length)
```

このコマンドはリード生成中にパラメータ概要と進捗メッセージを標準エラーへ表示します。FASTQ の品質値は現在、各リードで一様であり、指定したエラー率から計算されます。

入力 FASTA に含まれる小文字の `a/c/g/t/n` は、リード生成の前に大文字へ正規化されます。IUPAC 曖昧塩基は `N` に正規化され、`--max-n-ratio` の判定もこの正規化後の `N` 数を使います。

`.gz` で終わる FASTA 入力ファイルは gzip 圧縮入力として読み込まれます。変異後 FASTA とリード FASTQ の出力先が `.gz` で終わる場合は gzip 圧縮出力になります。`gen` は標準出力へ書き出すため、圧縮したランダム参照を作りたい場合は `gzip` へパイプしてください。

## 再現性

`--seed` を指定すると、同じコマンドとオプションの組み合わせで再現可能な結果を得られます。

```sh
wgsim gen --chromosome-lengths 10000 --seed 1 > reference.fa
wgsim mut --reference reference.fa --mutated-fasta mutated.fa --mutation-log mutations.tsv --seed 2
wgsim seq --reference mutated.fa --read1-fastq reads_1.fq --read2-fastq reads_2.fq --seed 3
```

各段階を再現可能にしつつ、段階ごとに独立したシミュレーションにしたい場合は、異なるシードを使います。

## 一般的なワークフロー

```sh
# 1. 参照配列を生成する。
wgsim gen --chromosome-lengths 100000,100000 --seed 1 > reference.fa

# 2. 変異を加える。
wgsim mut \
  --reference reference.fa \
  --mutated-fasta mutated.fa \
  --mutation-log mutations.tsv \
  --sub-rate 0.001 \
  --ins-rate 0.0001 \
  --del-rate 0.0001 \
  --seed 2

# 3. ペアエンドリードをシミュレートする。
wgsim seq \
  --reference mutated.fa \
  --read1-fastq reads_1.fq \
  --read2-fastq reads_2.fq \
  --depth 30 \
  --read1-len 150 \
  --read2-len 150 \
  --seed 3
```

## コードを読むための入口

このコードは、短い実装テクニックよりも、生物学的な概念に沿って読めることを重視して構成されています。

- `src/wgsim/dna.cr`
  - バイト単位の DNA 塩基、IUPAC 曖昧塩基の正規化、置換候補、reverse complement を定義します。
- `src/wgsim/mutate/mutation_simulator.cr`
  - 参照配列を 1 塩基ずつ走査し、生物学的変異タイプをサンプリングし、完全な変異履歴を記録します。
- `src/wgsim/mutate/mutation_event_builder.cr`
  - シミュレートされた置換、挿入、欠失を、明示的なイベントログレコードに変換します。
- `src/wgsim/sequencing/read_pair_simulator.cr`
  - DNA 断片をサンプリングし、read の向きを選び、ペアエンドリードを取り出し、`N` が多い read を除外したあと、シーケンスエラーを加えます。
- `src/wgsim/sequencing/error_model.cr`
  - 生物学的変異とは別に、シーケンスエラーをモデル化します。

コードを読むとき、特に重要な分離は次の 2 つです。

- 生物学的変異は `mut` で起こり、read が生成される前に適用されます。
- シーケンスエラーは `seq` で起こり、入力 FASTA から read がサンプリングされたあとに適用されます。

## 設計メモと将来のアイデア

- 体細胞変異
  - 広い表現: `SNVs`, `indels`, 大きな挿入、大きな欠失、転座を含める。
  - FASTA 内の完全な DNA 配列: FASTA ファイルにゲノム全体を含める。
- ハプロタイプ
  - 倍数性: 細胞の ploidy に応じて、相同染色体の数だけ FASTA レコードを含める。
- 構造変異
  - 逆位と融合: 逆位や融合のような構造変異を FASTA ファイルで正確に表現する。
- 局所増幅
  - extrachromosomal DNA: extrachromosomal DNA による染色体コピー数増加を、追加レコードとして含める。
- 圧縮しないゲノム表現
  - データ構造: モデルを単純に保つため、各塩基に `UInt8` や `ReferenceBase` 構造体を使う。
- 不均一性への対応
  - 細胞タイプごとの FASTA: 各細胞タイプが 1 つの FASTA ファイルを持つ。
  - 細胞タイプ比率: 各細胞タイプの比率を指定できるようにする。
- VCF ファイルには 2 つの役割がある。
  - 参照ゲノムとの差分を記録することで、現在の状態のスナップショットになる。
  - 遺伝的変異の詳細な記録であるとみなされる。
- 実際の個体ゲノムを観察して変異を推定しようとしても、イベントを完全に復元することはできません。
  - 一方、シミュレーションでは、発生した変異イベントの完全な一覧を持つことができます。

## 注意点と制限

- `mut` の変異イベントログは、現時点では VCF ではなく単純なタブ区切り形式です。
- `seq` は生物学的変異を追加しません。変異が必要な場合は `seq` の前に `mut` を使います。
- シーケンスエラーは一様な塩基置換としてモデル化されます。
- 小文字の `a/c/g/t/n` は受け付けられ、大文字へ正規化されます。それ以外の IUPAC 曖昧塩基は `N` に正規化されます。
- FASTA 入力と FASTA/FASTQ 出力は `fastx.cr` を通じて処理されます。パス指定の reader/writer は `.gz` から gzip を自動判定します。
- `seq` では、設定されたリード長より短いコンティグはスキップされます。
- すべてのコマンドは、再現性のために有効な実行パラメータを標準エラーへ出力します。
- マルチスレッド処理は未実装です。ビルド時に `-Dpreview_mt` を指定する必要はありません。
- 数値オプションは検証されます。率と確率は有効範囲内である必要があり、リード長と染色体長は正の値、`mut` の変異率の合計は `1.0` 以下である必要があります。
- このツールは実験的なものであり、検証済みの本番用シミュレータではありません。
