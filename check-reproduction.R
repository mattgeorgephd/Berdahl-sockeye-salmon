#!/usr/bin/env Rscript
#
# Did this render reproduce the committed results?
#
# Run after ./render-all.sh, from the project root. Compares every tracked
# result file in the working tree against its committed version at HEAD and exits
# non-zero if anything changed that should not have.
#
# `git diff --exit-code` cannot be used directly, for two reasons:
#
#   1. Re-rendered PNG and PDF bytes differ on every render (timestamps, font
#      rasterisation, device version) while the plots are identical.
#   2. apeglm's shrinkage is an iterative fit, so log2FoldChange and lfcSE move
#      in roughly the third decimal across package or platform versions. Those
#      are the values 02, 03 and 04 all write.
#
# So: images are reported and ignored; tables are compared structurally (same
# rows, same columns, same keys) and numerically with a relative tolerance; and
# significance calls at 0.05 must be identical, because a gene crossing the
# threshold changes the result even when the fold change barely moved.
#
# Anything this script cannot parse is a failure, not a pass. A file it does not
# understand is a file nobody is checking.

TOL        <- 1e-3     # relative tolerance on numeric columns
ABS_TOL    <- 1e-2     # absolute floor under the relative tolerance -- see below
PVAL_TOL   <- 1e-2     # looser, for p-value and FDR columns -- see below
PVAL_COLS  <- c("padj", "pvalue", "FDR", "over_represented_pvalue",
                "under_represented_pvalue")
CALL_COLS  <- c("padj", "FDR")   # adjusted columns: the 0.05 call is checked exactly
IMAGE_EXTS <- c("png", "pdf", "svg", "jpg", "jpeg", "html")

# Why there is an absolute floor: the first cross-platform render (Linux, in CI)
# moved apeglm's log2FoldChange by at most 0.0008 log2 units, and lfcSE by at
# most 0.0013. A purely relative tolerance failed both files anyway, on genes
# whose fold change is close to zero -- 0.0006 on an LFC of 0.125 is a 0.5%
# relative change and no result at all. A value passes if it is within
# ABS_TOL + TOL * |committed| of the committed value. baseMean and normalised
# counts are in the tens to thousands, so the relative term governs them; the
# floor matters only for the small-magnitude fold-change columns.
#
# Why only adjusted columns get the significance-call check: a raw p-value
# crossing 0.05 changes no conclusion -- every table is read at padj or FDR
# below 0.05. Checking raw p-values at that threshold produced 20 spurious
# "changed calls" in a GO table whose FDR calls had changed by 2.

# Why p-values get their own tolerance: they span thirty orders of magnitude
# here, so a relative comparison is brutally strict at the small end -- 1e-30 vs
# 1.1e-30 is a 10% relative change and no result at all. What matters about a
# p-value is which side of the threshold it falls on, and that is checked
# exactly, below, with no tolerance at all.
RESULT_DIRS <- c("tag-seq/DESEQ_output", "tag-seq/gene_tables", "tag-seq/GO_output")

changed <- system2("git", c("diff", "--name-only", "--", RESULT_DIRS), stdout = TRUE)
changed <- changed[nzchar(changed)]

if (length(changed) == 0) {
  cat("Reproduction check: PASS -- every tracked result file is byte-identical.\n")
  quit(status = 0)
}

## Read the committed version of a path without touching the working tree.
read_head_lines <- function(path) {
  con <- pipe(sprintf("git show %s", shQuote(paste0("HEAD:", path))), open = "r")
  on.exit(close(con))
  readLines(con, warn = FALSE)
}

is_csv <- function(lines) length(lines) > 0 && grepl(",", lines[[1]], fixed = TRUE)

parse_csv <- function(lines) {
  tryCatch(
    utils::read.csv(text = paste(lines, collapse = "\n"),
                    stringsAsFactors = FALSE, check.names = FALSE),
    error = function(e) NULL
  )
}

## Compare two parsed tables. Returns a character vector of problems; empty
## means "differences are within tolerance and change no conclusion".
compare_tables <- function(old, new, tol = TOL) {
  problems <- character(0)

  if (!identical(dim(old), dim(new))) {
    return(sprintf("dimensions changed: %d x %d committed, %d x %d rendered",
                   nrow(old), ncol(old), nrow(new), ncol(new)))
  }
  if (!identical(names(old), names(new))) {
    return("column names changed")
  }

  ## Match on a key rather than row order: ties in a padj sort can legitimately
  ## reorder, but the set of rows must not change. The single-gene-count tables
  ## have one row per gene per sample, so there the key is the pair; keying on
  ## gene alone matched every row to the first row for that gene and reported
  ## counts changed 635-fold when they had changed in the fourteenth digit.
  key_cols <- intersect(c("gene", "category"), names(old))
  if (length(key_cols) > 0) {
    key_cols <- c(key_cols[[1]], intersect("sample", names(old)))
    key_of   <- function(d) do.call(paste, c(d[key_cols], sep = "\r"))
    ko <- key_of(old); kn <- key_of(new)
    if (anyDuplicated(ko) || anyDuplicated(kn)) {
      return(sprintf("key (%s) is not unique; cannot match rows", paste(key_cols, collapse = ", ")))
    }
    if (!setequal(ko, kn)) {
      lost   <- setdiff(ko, kn)
      gained <- setdiff(kn, ko)
      return(sprintf("%s set changed: %d lost, %d gained (e.g. %s)",
                     paste(key_cols, collapse = "+"), length(lost), length(gained),
                     paste(gsub("\r", "/", utils::head(c(lost, gained), 3)), collapse = ", ")))
    }
    old <- old[match(kn, ko), , drop = FALSE]
  }

  for (col in names(old)) {
    a <- old[[col]]
    b <- new[[col]]

    if (is.numeric(a) && is.numeric(b)) {
      if (!identical(is.na(a), is.na(b))) {
        problems <- c(problems, sprintf("%s: NA pattern changed", col))
        next
      }
      ok <- !is.na(a)
      if (any(ok)) {
        if (col %in% PVAL_COLS) {
          rel <- abs(b[ok] - a[ok]) / pmax(abs(a[ok]), 1e-12)
          if (max(rel) > PVAL_TOL) {
            problems <- c(problems, sprintf("%s: max relative change %.3g exceeds %.3g",
                                            col, max(rel), PVAL_TOL))
          }
        } else {
          excess <- abs(b[ok] - a[ok]) - (ABS_TOL + tol * abs(a[ok]))
          if (max(excess) > 0) {
            i <- which.max(excess)
            problems <- c(problems, sprintf(
              "%s: change of %.3g at committed value %.3g exceeds %.3g + %.3g * |value|",
              col, abs(b[ok] - a[ok])[i], a[ok][i], ABS_TOL, tol))
          }
        }
      }
      ## A gene crossing 0.05 is a changed result however small the numeric move.
      if (col %in% CALL_COLS) {
        call_a <- !is.na(a) & a < 0.05
        call_b <- !is.na(b) & b < 0.05
        if (!identical(call_a, call_b)) {
          problems <- c(problems, sprintf("%s: %d significance call(s) at 0.05 changed",
                                          col, sum(call_a != call_b)))
        }
      }
    } else if (!identical(as.character(a), as.character(b))) {
      problems <- c(problems, sprintf("%s: non-numeric values changed", col))
    }
  }

  problems
}

images   <- character(0)
tolerated <- character(0)
failures <- character(0)

for (path in changed) {
  ext <- tolower(tools::file_ext(path))

  if (ext %in% IMAGE_EXTS) {
    images <- c(images, path)
    next
  }

  head_lines <- tryCatch(read_head_lines(path), error = function(e) NULL)
  if (is.null(head_lines)) {
    failures <- c(failures, sprintf("%s: not present at HEAD (new or renamed output)", path))
    next
  }
  work_lines <- readLines(path, warn = FALSE)

  if (!is_csv(head_lines)) {
    ## Space-separated tables and plain identifier lists carry no apeglm floats,
    ## so they have no reason to differ at all.
    failures <- c(failures, sprintf("%s: content changed (no tolerance applies to this format)", path))
    next
  }

  old <- parse_csv(head_lines)
  new <- parse_csv(work_lines)
  if (is.null(old) || is.null(new)) {
    failures <- c(failures, sprintf("%s: could not be parsed as CSV", path))
    next
  }

  problems <- compare_tables(old, new)
  if (length(problems) == 0) {
    tolerated <- c(tolerated, path)
  } else {
    failures <- c(failures, sprintf("%s: %s", path, paste(problems, collapse = "; ")))
  }
}

cat("Reproduction check\n")
cat("------------------\n")
cat(sprintf("%d tracked result file(s) differ from HEAD.\n\n", length(changed)))

if (length(images) > 0) {
  cat(sprintf("Re-rendered images, ignored (%d):\n", length(images)))
  cat(paste0("  ", images, collapse = "\n"), "\n\n", sep = "")
}
if (length(tolerated) > 0) {
  cat(sprintf("Tables within tolerance, same rows and same significance calls (%d):\n",
              length(tolerated)))
  cat(paste0("  ", tolerated, collapse = "\n"), "\n\n", sep = "")
}
if (length(failures) > 0) {
  cat(sprintf("FAILURES (%d):\n", length(failures)))
  cat(paste0("  ", failures, collapse = "\n"), "\n\n", sep = "")
  cat("Reproduction check: FAIL\n")
  cat("These are differences a version bump does not explain. Inspect with\n")
  cat("  git diff -- <path>\n")
  quit(status = 1)
}

cat("Reproduction check: PASS\n")
cat(sprintf(paste0("Differences are confined to re-rendered images and numeric drift within\n",
                   "%g + %g * |value| (relative %g for p-value columns). No row, no column\n",
                   "and no padj or FDR call at 0.05 changed.\n"), ABS_TOL, TOL, PVAL_TOL))
quit(status = 0)
