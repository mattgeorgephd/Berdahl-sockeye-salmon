# Alignment and assembly summary

## HISAT2 alignment rates

Extracted from alignment logs on Raven during initial processing:

### Gonad samples (n=15)

| Metric | Value |
|--------|-------|
| Overall alignment rate (mean) | 88.7% |
| Standard deviation | 2.21% |
| Min | 85.2% |
| Max | 92.1% |

**MultiQC:** See `tag-seq/QC/multiqc_gonad/` for detailed quality control report.

### Liver samples (n=15)

| Metric | Value |
|--------|-------|
| Overall alignment rate (mean) | 86.5% |
| Standard deviation | 0.82% |
| Min | 84.8% |
| Max | 87.9% |

**MultiQC:** See `tag-seq/QC/multiqc_liver/` for detailed quality control report.

## FastQC results

Quality control was run on both untrimmed and trimmed reads:

- **Untrimmed:** Results in `tag-seq/QC/fastqc/untrimmed/`
- **Trimmed:** Results in `tag-seq/QC/fastqc/trimmed/`

All samples passed basic quality checks. Most failed the adapter content check (expected, as 
reads carry TagSeq barcode sequences that are hard-trimmed before downstream analysis).

## Justification for sample exclusion (R5)

Gonad samples C05 and C17 were excluded from DESeq2 analysis after failing the sample 
correlation check in MultiQC. The sample-correlation heatmap (MultiQC report) shows these 
samples cluster separately from the rest of their treatment group, indicating potential 
quality issues or batch effects.

This exclusion is documented in `tag-seq/code/_common.R` (lines 33-38) and applied during 
`load_counts()`.
