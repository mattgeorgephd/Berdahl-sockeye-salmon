# Berdahl-sockeye-salmon

## Reproducibility

This repository has been rebuilt as a reproducible Quarto project (phases 0-4, see
`REPRODUCIBILITY-PLAN.md`). To reproduce the analysis:

```bash
# First-time setup, from R in the project root:
#   renv::restore()

# Then, from the shell in the project root:
./render-all.sh
```

`./render-all.sh` is the entry point, **not** `quarto render`.
`02-differential-expression.qmd` is parameterised by tissue and defaults to
liver, so a bare `quarto render` regenerates the liver results only and leaves
the gonad results untouched. The script renders it once per tissue, then the two
notebooks that consume its output.

Results land in `tag-seq/DESEQ_output/<tissue>/`, `tag-seq/gene_tables/` and
`tag-seq/GO_output/<tissue>/`, all of which are tracked in git — so a render
followed by

```bash
Rscript check-reproduction.R
```

is the reproduction test. That script compares every tracked result file against
its committed version, ignoring the two differences a re-render is expected to
produce — image bytes, and `apeglm` fold changes in the third decimal, since its
shrinkage is an iterative fit sensitive to the package version — and failing on
any changed row, column, or significance call at 0.05. `git diff --stat` gives
the raw view.

Rendered HTML goes to `docs/`, which is gitignored; the `render` GitHub Action
publishes it to Pages on every push to `main`. That Action is the real
reproducibility test: it restores `renv.lock` on a machine that has never seen
the project, renders, and runs the check above. A green run means the analysis
still reproduces from a clean checkout.

The upstream steps (alignment and assembly) are documented in
`tag-seq/code/01-upstream-alignment.qmd` with `eval: false` — they are meant to
run on Raven with access to Gannet storage, not on a laptop.

### What each notebook does

| Notebook | Reads | Writes |
|---|---|---|
| `01-upstream-alignment.qmd` | FASTQs on Gannet | count matrices (on Raven; `eval: false` here) |
| `02-differential-expression.qmd` | `tag-seq/data/` | `tag-seq/DESEQ_output/<tissue>/` |
| `03-gene-tables.qmd` | `*-SIG-DEG-apeglm.csv` | `tag-seq/gene_tables/` |
| `04-enrichment.qmd` | `*-ALL-DEG-apeglm.csv`, GAF, KEGG | `tag-seq/GO_output/<tissue>/` |

Input integrity is recorded in `CHECKSUMS.sha256` and checked at the start of
every render (a mismatch warns, it does not stop). Verify by hand with
`shasum -c CHECKSUMS.sha256`.

`archive/` holds superseded material kept for reference only: the original
upstream shell transcript and the 2023 DAVID web-tool output. Nothing in it is
rendered or read by the analysis.

For the full audit and the remaining work, see `REPRODUCIBILITY-PLAN.md`.

What still stands between this repository and a *Molecular Ecology* submission
is tracked in `SUBMISSION-CHECKLIST.md`.

---

### Locations
1. [Gannet folder](https://gannet.fish.washington.edu/panopea/berdahl-sockeye-salmon/)
2. [Manuscript](https://docs.google.com/document/d/19xcEKJfSdz6b7KGZAEr76w9NrCF5RPQ99FFtRt-G-wI/edit?usp=sharing)

### Github issues:
1. [Sam's initial experiments w/ RNA extraction](https://github.com/RobertsLab/resources/issues/1307)
2. [Matt & Sam - issues with RNA extractions](https://github.com/RobertsLab/resources/issues/1410)
3. [GSAF sequencing results](https://github.com/RobertsLab/resources/issues/1501)

### Sequencing:
1. Salmon samples shipped to UT Austin GSAF on 5/24. Received 5/25. Assigned Job number JA22192.
2. Sample list and plate map available [here](https://www.dropbox.com/s/snq453edfxeor6t/Berdahl_sockeye_salmon.xlsx?dl=0)
3. Quote available [here](https://www.dropbox.com/s/znk1cikjtrj9v6n/GSAF_Quote_Job_JA22192_2022-05-09.pdf?dl=0)
4. GSAF sample manifest available [here](https://www.dropbox.com/s/9yuso7jhkazikrt/GSAF%20Sample%20Manifest_Job%23JA22192_2022-05-12.pdf?dl=0)

### Pertinent Documents
1. Sample attributes [list](https://docs.google.com/spreadsheets/d/1HVCK9HVTzWEkBT5vnbK97zJvnE4Amco5NPkmf_W9yVw/edit?usp=sharing)
