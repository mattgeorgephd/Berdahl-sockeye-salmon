# tag-seq/sequences

Derived genome tracks for the upstream (FASTQ to count matrix) half of the
pipeline, which runs on Raven. Nothing here is read by notebooks 02-04.

| File | Size | Role |
|---|---|---|
| `GCF_006149115.2_Oner_1.1_genomic-sequence-lengths.txt` | 556 KB | `bedtools -faidx` input for the mRNA feature track step in `01-upstream-alignment.qmd` |

## Removed: GCF_006149115.2_Oner_1.1_mRNA.gff

This file was tracked at **zero bytes** (finding E7). It is a derived
intermediate: `01-upstream-alignment.qmd` ("Generate mRNA feature track") writes
it by grepping mRNA features out of the genomic GFF and piping them through
`bedtools`, and StringTie then consumes it as `-G`. An empty tracked file
asserts that the artefact exists when it does not, so it has been untracked
rather than left in place.

To regenerate it, run the "Generate mRNA feature track" chunk of
`01-upstream-alignment.qmd` on Raven. Nothing downstream needs it: goseq's gene
lengths come from `genome/GCF_006149115.2_Oner_1.1_feature_table.txt`, which is
committed and complete.
