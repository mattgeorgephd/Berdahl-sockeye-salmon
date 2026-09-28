#!/usr/bin/env bash
#
# Render the whole analysis. This is the entry point -- not `quarto render`.
#
# `quarto render` renders each notebook once, and 02 is parameterised by tissue
# with liver as its default, so a bare project render regenerates the liver
# results and silently leaves the gonad results as they were (finding B6). This
# script renders 02 once per tissue, then the two notebooks that read its
# output, in that order.
#
# First-time setup, from R in the project root:
#     renv::restore()
#
# Then, from the shell in the project root:
#     ./render-all.sh
#
# Results are written to tag-seq/DESEQ_output/<tissue>/, tag-seq/gene_tables/
# and tag-seq/GO_output/<tissue>/. All three are tracked in git, so
# `git diff --stat` after this script is the reproduction test: the only
# expected differences are re-rendered image bytes and apeglm fold changes in
# the third decimal.
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")"

# Upstream FASTQ -> count matrix. Every chunk is eval: false; this renders the
# documentation of what was run on Raven, not the pipeline itself.
echo "=== 01 upstream (documentation only, eval: false) ==="
quarto render tag-seq/code/01-upstream-alignment.qmd

# Differential expression, once per tissue.
echo "=== 02 differential expression (liver, gonad) ==="
tag-seq/code/render-differential-expression.sh

# Both of these read the CSVs 02 has just written, so they must follow it.
echo "=== 03 gene tables ==="
quarto render tag-seq/code/03-gene-tables.qmd

echo "=== 04 enrichment ==="
quarto render tag-seq/code/04-enrichment.qmd

# Landing page. Rendered last so its links point at pages that now exist.
echo "=== index (landing page) ==="
quarto render index.qmd

echo
echo "Done. Rendered site in docs/ (docs/index.html)."
echo
echo "Reproduction check:"
echo "  Rscript check-reproduction.R"
echo
echo "That compares every tracked result file against HEAD, ignoring re-rendered"
echo "image bytes and numeric drift within 1e-3, and fails on any changed row,"
echo "column or significance call. For the raw view:"
echo "  git diff --stat -- tag-seq/DESEQ_output tag-seq/gene_tables tag-seq/GO_output"
