#!/usr/bin/env bash
# Render the differential-expression notebook once per tissue.
#
# Run from the project root. Results are written to
# tag-seq/DESEQ_output/<tissue>/ ; because those files are tracked in git,
# `git diff` after this script is the reproduction test.
set -euo pipefail

# The per-tissue file name is set through the output-file metadata key rather
# than --output. --output takes a bare filename and drops it at the root of the
# output directory, away from the other notebooks, and under Quarto 1.10 its
# self-contained post-processing then looked for the _files/ resource directory
# at the project root and failed with NotFound. output-file keeps every rendered
# notebook together in docs/tag-seq/code/, which is where index.qmd links.
for tissue in liver gonad; do
  echo "--- rendering ${tissue} ---"
  quarto render tag-seq/code/02-differential-expression.qmd \
    -P "tissue:${tissue}" \
    -M "output-file:02-differential-expression-${tissue}.html"
done
