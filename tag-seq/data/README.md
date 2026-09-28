# tag-seq/data

What each tracked file is, and which notebook reads it. Written to close finding
E11: 39 MB of this repository was tracked input that no current notebook reads,
with nothing to say whether it was still needed.

| File | Size | Role | Read by |
|---|---|---|---|
| `onerka_gene_count_matrix-gonad.csv` | 4.0 MB | **input** — gene-level counts, 37,942 genes x 30 samples, from `prepDE.py` | `02` via `load_counts()` |
| `onerka_gene_count_matrix-liver.csv` | 3.7 MB | **input** — same, liver | `02` via `load_counts()` |
| `treatments-gonad.csv` | 599 B | **input** — sample to treatment map, 15 territorial / 15 social | `02` via `load_counts()` |
| `treatments-liver.csv` | 599 B | **input** — same, liver | `02` via `load_counts()` |
| `transcript_count_matrix-gonad.csv` | 6.1 MB | provenance only — transcript-level counts from the same `prepDE.py` run | nothing |
| `transcript_count_matrix-liver.csv` | 5.7 MB | provenance only — same, liver | nothing |
| `onerka_merged-liver.gtf` | 21 MB | provenance only — StringTie merged annotation used to produce the liver matrices | nothing |

The four input files are checksummed in `CHECKSUMS.sha256` and verified at the
start of every render.

## On the three provenance-only files

The analysis is gene-level throughout, so the transcript matrices are never
read; the merged GTF is the annotation the gene matrices were counted against
and is referenced only by the archived upstream transcript
(`archive/1_process-tagseq-data-salmon.Rmd`). They are kept because they are the
only committed record of what the upstream pipeline actually produced, and
regenerating them needs Raven.

They are, however, 33 MB of the repository, and `onerka_merged-liver.gtf` has no
gonad counterpart — so it documents half the pipeline. **Open decision:** either
keep them and treat this table as the justification, or move all three to Gannet
alongside the FASTQs and record the URL here. Deferred deliberately rather than
resolved by deletion.
