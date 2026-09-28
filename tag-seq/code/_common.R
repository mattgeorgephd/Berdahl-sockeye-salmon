## Shared setup for the sockeye TagSeq notebooks.
##
## Sourced from the project root -- _quarto.yml sets execute-dir: project, so
## every path below is written once and means the same thing everywhere.

# ---- paths ------------------------------------------------------------------

PATHS <- list(
  data   = "tag-seq/data",
  genome = "tag-seq/genome",
  seqs   = "tag-seq/sequences",
  output = "tag-seq/DESEQ_output"
)

# ---- per-tissue configuration -----------------------------------------------

## Everything that differed between the two near-identical DESeq2 notebooks
## (finding E5) is collected here. The output file prefixes differ in case for
## historical reasons -- liver files are "liver-*", gonad files are "GONAD-*" --
## and are kept as they are so the committed results stay at the same paths.
tissue_config <- function(tissue) {
  cfg <- switch(
    tissue,
    liver = list(
      prefix         = "liver",   # liver-PCA.png, liver-SIG-DEG-apeglm.csv, ...
      heatmap_prefix = "liver",   # liver_heatmap_pval_genes_apeglm.png
      exclude        = character(0),
      pca_xlim       = c(-100, 100)
    ),
    gonad = list(
      prefix         = "GONAD",
      heatmap_prefix = "gonad",
      ## C05 and C17 were dropped on the basis of the MultiQC sample-correlation
      ## heatmap. In the .Rmd this was an uncommented pair of lines in gonad and
      ## the same pair commented out in liver, with no recorded criterion
      ## (finding R5). Phase 4 commits the MultiQC output that justifies it.
      exclude        = c("C05", "C17"),
      pca_xlim       = c(-150, 150)
    ),
    stop("unknown tissue: ", tissue, " (expected 'liver' or 'gonad')")
  )
  cfg$tissue <- tissue
  cfg$dir    <- file.path(PATHS$output, tissue)
  cfg
}

## Build an output path inside this tissue's results directory.
out_path <- function(cfg, ...) file.path(cfg$dir, paste0(...))

# ---- sample identity --------------------------------------------------------

## Derive the treatment-table sample ID from a StringTie count-matrix column.
##
## prepDE.py names columns after the GTF files: "01B_S43_R1.gtf". The treatment
## tables use "B01". The mapping is: take the token before the first underscore
## ("01B") and swap its number and tissue letter ("B01").
##
## The .Rmd did this positionally -- colnames(cts) <- row.names(trt_list) -- and
## then "checked" the result with all(colnames(cts) %in% rownames(coldata)),
## which is unconditionally TRUE after the rename (finding R1). Any prepDE.py
## re-run that emitted columns in a different order would have silently
## mislabelled every sample.
sample_ids_from_columns <- function(cols) {
  tag <- sub("_.*$", "", sub("\\.gtf$", "", cols))
  bad <- !grepl("^[0-9]+[A-Za-z]$", tag)
  if (any(bad)) {
    stop("count matrix columns do not look like '<number><tissue letter>_...': ",
         paste(cols[bad], collapse = ", "))
  }
  sub("^([0-9]+)([A-Za-z])$", "\\2\\1", tag)
}

## Take the gene identifier from a StringTie row name.
##
## Row names are "gene-<id>|<id>": the identifier is a LOC number for genes
## with no assigned symbol ("gene-LOC115144855|LOC115144855") and a real symbol
## for the rest ("gene-arhgap8|arhgap8"). The part after the pipe is that
## identifier in both cases, and it is unique across all 37,942 genes.
##
## The .Rmd instead split each name on the literal "LOC" and kept the third
## piece, which works for LOC-numbered genes and produces the string "LOCNA"
## for every symbol-named one -- 4,731 genes, 12.5% of the annotation. Because
## data.frame() then de-duplicates row names, those genes reached the published
## tables as LOCNA.1, LOCNA.2292 and so on: identifiers that correspond to
## nothing and join to nothing, and that the gene tables consequently dropped.
## In the committed results that was 3 of 31 significant liver genes and 309 of
## 1,630 significant gonad genes (finding R8).
gene_ids_from_rownames <- function(rn) {
  ids <- sub("^.*\\|", "", rn)
  if (anyDuplicated(ids)) {
    stop("gene identifiers are not unique: ",
         paste(unique(ids[duplicated(ids)])[1:5], collapse = ", "))
  }
  ids
}

# ---- data loading -----------------------------------------------------------

## Load the count matrix and treatment table for one tissue, matched on sample
## ID rather than on column position, and return them already aligned.
load_counts <- function(cfg) {
  coldata <- read.csv(file.path(PATHS$data, paste0("treatments-", cfg$tissue, ".csv")),
                      sep = ",", header = TRUE, row.names = "ID")

  ## check.names = FALSE: the StringTie columns start with a digit
  ## ("01B_S43_R1.gtf"), and read.csv would otherwise silently rename them to
  ## "X01B_S43_R1.gtf". The .Rmd never noticed because it overwrote the column
  ## names positionally before ever reading them.
  cts <- as.matrix(read.csv(
    file.path(PATHS$data, paste0("onerka_gene_count_matrix-", cfg$tissue, ".csv")),
    sep = ",", header = TRUE, row.names = "gene_id", check.names = FALSE))

  ids <- sample_ids_from_columns(colnames(cts))

  ## The three assertions the old tautological check should have been.
  if (anyDuplicated(ids)) {
    stop("duplicate sample IDs derived from count matrix columns: ",
         paste(unique(ids[duplicated(ids)]), collapse = ", "))
  }
  if (!setequal(ids, rownames(coldata))) {
    stop("count matrix and treatment table do not describe the same samples.\n",
         "  only in counts:     ", paste(setdiff(ids, rownames(coldata)), collapse = ", "), "\n",
         "  only in treatments: ", paste(setdiff(rownames(coldata), ids), collapse = ", "))
  }
  colnames(cts) <- ids
  cts <- cts[, rownames(coldata), drop = FALSE]   # align by name, not by luck
  stopifnot(identical(colnames(cts), rownames(coldata)))

  rownames(cts) <- gene_ids_from_rownames(rownames(cts))

  ## Excluded samples are dropped from both objects together.
  if (length(cfg$exclude)) {
    missing <- setdiff(cfg$exclude, rownames(coldata))
    if (length(missing)) stop("cannot exclude absent sample(s): ", paste(missing, collapse = ", "))
    keep    <- setdiff(rownames(coldata), cfg$exclude)
    coldata <- coldata[keep, , drop = FALSE]
    cts     <- cts[, keep, drop = FALSE]
  }

  ## territorial is the treatment, social is the reference. Made explicit so the
  ## sign of every log2FoldChange no longer depends on "social" happening to
  ## sort before "territorial" alphabetically (finding R3).
  coldata$trt    <- relevel(factor(coldata$trt), ref = "social")
  coldata$tissue <- factor(coldata$tissue)

  list(cts = cts, coldata = coldata)
}

## Per-gene annotation: description, NCBI GeneID and transcript length.
##
## Built from the assembly feature table rather than Onerka_LOCID_gene_table.txt,
## which is keyed entirely by LOC identifiers (33,210 of our 37,942 genes) and so
## could never annotate a symbol-named gene. The feature table covers 37,929 and
## agrees with the old table on every one of the 33,210 they share -- verified,
## so this is a strict superset, not a different annotation.
##
## Length is the median mRNA interval per gene. goseq's nullp() takes it as
## bias data; the test itself is hypergeometric (see 04), so the length enters
## the diagnostic plot but not the p-values. It comes from here rather than from
## sequences/GCF_006149115.2_Oner_1.1_mRNA.gff, which was tracked at zero bytes
## and has since been untracked (finding E7); the feature table is committed and
## complete, so no upstream step has to be re-run to get lengths.
load_gene_annotation <- function() {
  ft <- read.delim(file.path(PATHS$genome, "GCF_006149115.2_Oner_1.1_feature_table.txt"),
                   sep = "\t", quote = "", stringsAsFactors = FALSE, check.names = FALSE)
  names(ft)[1] <- "feature"

  m <- ft[ft$feature == "mRNA" & nzchar(ft$symbol), ]

  first_name <- tapply(m$name, m$symbol, function(x) {
    x <- x[nzchar(x)]
    if (length(x)) x[[1]] else NA_character_
  })
  gene_id <- tapply(m$GeneID, m$symbol, function(x) x[[1]])
  len     <- tapply(m$feature_interval_length, m$symbol,
                    function(x) stats::median(x, na.rm = TRUE))

  data.frame(gene        = names(first_name),
             GeneID      = as.integer(gene_id[names(first_name)]),
             description = unname(first_name),
             length      = as.numeric(len[names(first_name)]),
             stringsAsFactors = FALSE)
}

## Kept for the notebooks that only need gene -> description.
load_feature_table <- function() {
  load_gene_annotation()[, c("gene", "description")]
}

# ---- plotting ---------------------------------------------------------------

my_theme <- ggplot2::theme(
  line             = ggplot2::element_line(linewidth = 1.5),
  rect             = ggplot2::element_rect(linewidth = 1.5),
  text             = ggplot2::element_text(size = 14, colour = "black"),
  panel.background = ggplot2::element_blank(),
  panel.grid.major = ggplot2::element_blank(),
  panel.grid.minor = ggplot2::element_blank(),
  axis.text.x      = ggplot2::element_text(size = 16, colour = "black"),
  axis.text.y      = ggplot2::element_text(size = 16, colour = "black"),
  axis.title.x     = ggplot2::element_text(margin = ggplot2::margin(t = 10)),
  axis.title.y     = ggplot2::element_text(margin = ggplot2::margin(r = 10)),
  axis.ticks.x     = ggplot2::element_line(colour = "black"),
  axis.ticks.y     = ggplot2::element_line(colour = "black"),
  panel.border     = ggplot2::element_rect(colour = "black", fill = NA, linewidth = 1.5),
  legend.key       = ggplot2::element_blank()
)

## Treatment colours, derived from coldata rather than hardcoded run lengths.
## The .Rmd wrote rep("royalblue1", 15) / rep("red3", 15) for liver and 14 / 14
## for gonad, assuming both the group sizes and the column order (finding R4).
TRT_COLOURS <- c(territorial = "royalblue1", social = "red3")

trt_side_colours <- function(coldata) unname(TRT_COLOURS[as.character(coldata$trt)])

# ---- input integrity ---------------------------------------------------------

## Check the input files against CHECKSUMS.sha256 (finding E12).
##
## Finding R1 was a count matrix whose columns had been reordered by a re-run of
## prepDE.py, silently mislabelling every sample; the loader assertions above
## catch that case now. This is the same failure mode one layer further out: an
## input file that changed without anyone noticing, so that the committed
## results no longer correspond to the committed inputs.
##
## A mismatch warns rather than stops. A deliberate data update should not block
## a render -- it should be loud, and then re-recorded:
##     shasum -a 256 $(awk '!/^#/ && NF {print $2}' CHECKSUMS.sha256) > CHECKSUMS.sha256
##
## Paths in the manifest are relative to the project root, which is where every
## chunk runs (execute-dir: project). Skipped with a message if the manifest or
## the digest package is absent, so no notebook gains a hard dependency on it.
verify_inputs <- function(manifest = "CHECKSUMS.sha256") {
  if (!file.exists(manifest)) {
    message("verify_inputs(): ", manifest, " not found; skipping integrity check")
    return(invisible(NULL))
  }
  if (!requireNamespace("digest", quietly = TRUE)) {
    message("verify_inputs(): package 'digest' not installed; skipping integrity check")
    return(invisible(NULL))
  }

  lines <- readLines(manifest, warn = FALSE)
  lines <- trimws(lines)
  lines <- lines[nzchar(lines) & !startsWith(lines, "#")]

  expected <- sub("^([0-9a-fA-F]+)[[:space:]]+[*]?(.*)$", "\\1", lines)
  paths    <- sub("^([0-9a-fA-F]+)[[:space:]]+[*]?(.*)$", "\\2", lines)

  missing  <- character(0)
  mismatch <- character(0)
  for (i in seq_along(paths)) {
    if (!file.exists(paths[i])) {
      missing <- c(missing, paths[i])
      next
    }
    got <- digest::digest(paths[i], algo = "sha256", file = TRUE)
    if (!identical(tolower(got), tolower(expected[i]))) {
      mismatch <- c(mismatch, paths[i])
    }
  }

  if (length(missing) > 0) {
    warning("input file(s) listed in ", manifest, " are missing: ",
            paste(missing, collapse = ", "), call. = FALSE)
  }
  if (length(mismatch) > 0) {
    warning("input file(s) do not match ", manifest, ": ",
            paste(mismatch, collapse = ", "),
            ". The analysis will still run, but the committed results no longer ",
            "correspond to these inputs.", call. = FALSE)
  }
  if (length(missing) == 0 && length(mismatch) == 0) {
    message("verify_inputs(): ", length(paths), " input files match ", manifest)
  }

  invisible(list(checked = paths, missing = missing, mismatch = mismatch))
}

## Runs whenever this file is sourced, i.e. at the top of notebooks 02, 03 and 04.
verify_inputs()
