# archive

Superseded material, kept for reference. **Nothing here is rendered, executed or
read by the analysis.** The directory sits outside the Quarto project's
`render:` list in `_quarto.yml`, so `quarto render` and `./render-all.sh` both
ignore it.

## 1_process-tagseq-data-salmon.Rmd

The original upstream pipeline: a shell transcript of one session on one machine
— absolute paths under `/home/shared/`, `wget` against Gannet, `rsync` between
local directories, a bowtie2 branch that was never used and a brain-tissue
branch that was never resolved.

It was previously at `tag-seq/code/`, where a project-wide `quarto render`
picked it up: ~40 `{bash}` chunks with no `eval` guard on any of them (finding
B5). Moving it here takes it out of render scope, and a
`knitr::opts_chunk$set(eval = FALSE)` guard was added at the top as a second
line of defence.

Current version: `tag-seq/code/01-upstream-alignment.qmd`, with paths
parameterised, bowtie2 removed and the brain branch marked unresolved.

## david-2023/

`DAVID_GOterms.txt` and `DAVID_KEGG_pathway.txt`, from the 2023 analysis. These
were sitting in `tag-seq/DESEQ_output/gonad/` among files that a render
overwrites, which made irreproducible web-tool output look like a regenerated
result (finding E13).

Two reasons they are archived rather than maintained:

1. They cannot be reproduced from this repository. They are output from
   [DAVID](https://david.ncifcrf.gov/) pasted in by hand, with no record of the
   gene list submitted, the background used, or the tool version.
2. They are not enrichment results. Both are per-gene reports — a gene with its
   annotated terms or pathways, one row each — with no over-representation
   statistic and no FDR anywhere in either file.

The reproducible replacements are `tag-seq/GO_output/<tissue>/`: goseq's
hypergeometric test against the NCBI GO annotation for this assembly and
against the KEGG organism `one` map, both reported at FDR < 0.05 with the gene list, the
background and the package versions recorded in the render.
