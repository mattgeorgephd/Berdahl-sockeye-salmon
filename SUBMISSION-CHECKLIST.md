# Submission checklist — Molecular Ecology

What stands between the current state of this repository and a manuscript that
can be submitted to *Molecular Ecology*. Written 2026-09-26 from a review of the
code, the committed result tables, the CI history, the Quarto draft at
`manuscript/manuscript.qmd`, and the linked Google Doc (which contains only a
skeleton methods section and no site, behaviour, or discussion text).

Tick items off here as they close, and record where the evidence landed. The
companion document `REPRODUCIBILITY-PLAN.md` covers the analysis audit; this
one covers only what the journal and its reviewers will need.

**Baseline on 2026-09-26.** The render workflow is green on `main` (last run
2026-09-07, restoring `renv.lock` on a clean runner and reproducing every
DESeq2 table and significance call). The draft is ~3,900 words of body text
with numbers computed from the result tables at render time, 37 references,
one composite figure and four tables. The manuscript is *not* rendered by CI.

---

## A. Blocking — cannot submit without these

### A1. Sex of the fish, and whether it confounds phenotype

- [ ] Obtain sex and maturity stage for all 30 fish from the dissection
      records (the sample-attributes sheet linked in `README.md`, if it holds
      them; it could not be opened during this review).
- [ ] Reconcile with the marker-gene evidence. The draft states all gonads
      were ovarian, but no notebook computes the marker values it quotes
      (112–410 CPM for *foxl2*), and `amh` — a testis marker — is itself
      differentially expressed (log2FC −0.90, padj 0.032, baseMean 87) in
      `tag-seq/DESEQ_output/gonad/GONAD-ALL-DEG-apeglm.csv`. Either put the
      marker-gene check into notebook 02 (or a new notebook) so the numbers are
      computed, or remove the inference and rely on the records.
- [ ] If sexes are mixed across phenotypes, re-fit the gonad model with sex as
      a covariate (`~ sex + trt`) and re-derive every downstream table. This
      could change the central result.
- [ ] If maturity stage or gonadosomatic index was recorded, test it as a
      covariate. The Discussion already concedes that territorial fish may
      simply be closer to spawning; reviewers will treat that as the default
      alternative explanation unless it is tested.

### A2. Field methods (only the Berdahl group can supply these)

- [ ] Collection site(s), water body, dates.
- [ ] Behavioural classification: the criteria that made a fish *territorial*
      or *social*, who scored it, observation duration, whether scoring
      preceded capture, and how the 15 + 15 were chosen from the fish
      observed.
- [ ] Capture and euthanasia method; time from capture to tissue preservation.
- [ ] Body length and mass per fish (supplementary table).
- [ ] Permits and animal-care approval (IACUC protocol number, collection
      permit numbers).
- [ ] Why brain and blood were not sequenced (draft says brain RNA yields were
      insufficient — confirm).

### A3. Raw data deposit

- [ ] Register a BioProject and BioSamples (30 fish, two tissues each).
- [ ] Deposit all 60 FASTQ files in SRA. Consider GEO instead, which takes the
      count matrices alongside the reads and issues one accession for both.
- [ ] Record accessions in `index.qmd`, `manuscript.qmd` (Data and code
      availability), and `README.md`.
- [ ] Reviewers must be able to reach the data at submission; keep the Gannet
      URL as a secondary location until the accession is public.

### A4. Code archive with a DOI

- [ ] Add `LICENSE` (the repository currently has none; GitHub reports
      `license: None`).
- [ ] Add `CITATION.cff` with the author list and, once minted, the Zenodo DOI.
- [ ] Decide on the 33 MB of provenance-only files listed as an open decision
      in `tag-seq/data/README.md`, and on `Onerka_LOCID_gene_table.txt`
      (`tag-seq/genome/README.md`), before the archive is cut.
- [ ] Tag a release and mint a Zenodo DOI. GitHub alone is not an acceptable
      archive for *Molecular Ecology*.

### A5. The C05 / C17 exclusion (audit findings R5, E9)

- [ ] Commit the MultiQC reports for both tissues into
      `tag-seq/QC/multiqc_gonad/` and `tag-seq/QC/multiqc_liver/` (currently
      placeholders), **or** compute the outlier criterion inside notebook 02
      (e.g. sample-correlation or PCA distance with a stated threshold) so the
      exclusion is derived rather than hardcoded in `tag-seq/code/_common.R`.
- [ ] Fix `tag-seq/QC/ALIGNMENT_SUMMARY.md`: it reports n=15 per tissue for
      matrices with 30 columns, and cites logs that are not in the repository.
      Commit per-sample alignment rates and library sizes as a supplementary
      table.

### A6. Sequencing details

- [ ] Instrument, read length and run type (single-end assumed) from the GSAF
      job documents (JA22192 gonad, JA22330 liver; Dropbox links in
      `README.md`). Replace the placeholder in `manuscript.qmd`.
- [ ] Cutadapt, FastQC and MultiQC versions (notebook 01 lists the tools but
      not every version).

### A7. Front and back matter

- [ ] Author list, affiliations, corresponding author, ORCID for the
      corresponding author (required) and ideally all authors.
- [ ] Author contributions (CRediT).
- [ ] Funding and acknowledgements.
- [ ] Data Accessibility and Benefit-Sharing Statement in the journal's
      required form (data locations with accessions, code DOI, and the
      benefit-sharing sentence, which depends on where the fish were
      collected).
- [ ] Conflict of interest statement.

### A8. Length limits

- [ ] Abstract is 273 words; the limit is 250.
- [ ] Keywords: eight listed; reduce to six.

---

## B. Analysis changes to make before the numbers are frozen

### B1. Independent-filtering mismatch between unshrunken and shrunken tables

In `tag-seq/code/02-differential-expression.qmd` (chunk `contrasts`) the
unshrunken results are computed with `alpha = 0.05`, but the three
`lfcShrink()` calls omit `res =`, so they call `results()` internally with the
default `alpha = 0.1` and carry that padj. This is why the draft has a
Limitations paragraph explaining 66 versus 31 liver genes and 1,653 versus
1,630 gonad genes.

- [ ] Pass the alpha-0.05 results object into each shrinkage call:
      `lfcShrink(dds, coef = 2, res = res_table, type = "apeglm")` (and the
      same for `normal` and `ashr`).
- [ ] Re-render with `./render-all.sh`, review the diff in significant-gene
      counts, and commit the new baseline so `check-reproduction.R` passes.
- [ ] Update every number in `index.qmd` that is typed rather than computed
      (the results tables there are hand-written), and delete the Limitations
      paragraph about the two conventions from `manuscript.qmd`.

### B2. Marker-gene and covariate work from A1

- [ ] Whatever A1 decides, the computation lives in a notebook and the
      manuscript reads its output. No hand-transcribed CPM values.

### B3. Questions salmonid reviewers will ask

- [ ] How multi-mapping reads were handled by HISAT2 given the salmonid
      whole-genome duplication (the two serum amyloid A-5 paralogues,
      `LOC115112426` and `LOC115112427`, are the headline result). State the
      HISAT2 `-k` setting and whether secondary alignments were counted by
      `prepDE.py`.
- [ ] Confirm nothing was lost in the RefSeq feature-table join (11 of 5,646
      liver and 12 of 18,935 gonad rows lack a description — say so).
- [ ] Per-sample sequencing depth, alignment rate and genes detected, as a
      supplementary table.

---

## C. Manuscript revisions for this journal

### C1. Framing

*Molecular Ecology* publishes work that uses molecular tools to answer
questions in ecology, evolution and behaviour. The draft reads as a gene
inventory in places.

- [ ] Introduction: state explicit hypotheses with tissue-specific predictions
      (e.g. reproductive-investment hypothesis predicts gonadal translation
      and energy-metabolism differences; cost-of-aggression hypothesis
      predicts hepatic and gonadal stress/immune induction). Say which one the
      data favour.
- [ ] Discussion: cut gene-by-gene narration to the two gonadal programmes
      (biosynthetic/energetic; acute-phase), the vasotocin finding, the
      *amh* finding once A1 is resolved, and the maturation-stage confound.
- [ ] Move most of the Wallenius-versus-hypergeometric section to a short
      methods paragraph plus a supplementary note with the length-decile
      figure from notebook 04. It is a genuine methodological contribution
      for 3′-tag data but is currently a page of the Discussion.
- [ ] Verify the methods text against the lab notebook where the Google Doc
      and the draft disagree: Turbo DNase kit versus on-column DNase I; GCA
      versus GCF accession; StringTie 2.2.0 versus 2.2.1; "gill tissue" in the
      Google Doc is a typo.

### C2. Figures

`figures/figure_X.png` is exported from a hand-assembled PowerPoint file, uses
default ggplot styling, does not colour the volcanoes by significance, has no
heatmap colour legend, and is produced by no script (`figures/README.md`).

- [ ] Add a figure notebook (e.g. `tag-seq/code/05-figures.qmd`, added to the
      render list and to `render-all.sh`) that builds the composite from the
      DESeq2 objects with `patchwork` or `cowplot`, so the figure tracks the
      data.
- [ ] Figure 1: PCA, volcano (coloured by padj < 0.05, headline genes
      labelled), heatmap with legend; both tissues.
- [ ] Figure 2: enrichment dot plot, KEGG and GO, gonad.
- [ ] Figure 3: per-group normalised counts for the headline genes (two SAA-5
      paralogues, equistatin-like, *hspb11*, vasotocin-neurophysin VT1, *amh*,
      and the 11 genes shared between tissues).
- [ ] Export at journal resolution (vector PDF/EPS, or TIFF ≥ 300 dpi) with a
      colour-blind-safe palette; check the current royalblue/red3 pairing.

### C3. Tables

- [ ] Main text: at most two tables (KEGG pathways; top gonad genes). The
      35-row GO table and the 31-row liver table go to the supplement.
- [ ] Supplementary tables: sample metadata and QC (A2, A5, B3); full DE
      tables per tissue (all shrinkage estimators); full GO and KEGG results;
      gene tables from `tag-seq/gene_tables/`.

### C4. Mechanics

- [ ] Add `manuscript/manuscript.qmd` to the render workflow so the docx is
      built and proven on every push.
- [ ] Add a *Molecular Ecology* CSL file and set `csl:` in the YAML header.
- [ ] Add a docx reference document with double spacing and continuous line
      numbers for review.
- [ ] Check the reference list for coverage: sockeye-specific spawning
      behaviour (female nest competition), 3′-tag analysis practice, salmonid
      acute-phase/immune genes, and recent peripheral-tissue social-status
      transcriptomics.
- [ ] Cover letter.
- [ ] Remove the `[[...]]` placeholders; grep the rendered docx for `[[`
      before submitting.

---

## D. Repository streamlining (do before the Zenodo release)

Added 2026-09-26 after a second pass over the repository layout. The
scaffolding — one entry point, numbered notebooks, tracked and checksummed
results, CI — is right. What follows is what a reviewer would meet on arrival
that gets in the way. Items D1 and D2 regenerate every result table, so do
them in the same pass as B1 and rebaseline `check-reproduction.R` once.

### D1. Naming that will confuse supplementary-table readers

- [ ] Use one case for the per-tissue output prefixes (`liver-*` and
      `GONAD-*` today; `tissue_config()` in `tag-seq/code/_common.R`).
- [ ] Rename the `treatment` column in the DE tables, which holds the tissue
      name (`annotate_genes()` in notebook 02), to `tissue`.
- [ ] Rename the `DEGs_all-genes*` rows of `*-gene-counts.csv` to say
      "genes tested"; they are not DEG counts.
- [ ] Rename `trt` to `phenotype` in `tag-seq/data/treatments-*.csv`, the
      DESeq2 design and the plots, and re-record the input checksums.

### D2. Track only the results the manuscript uses

`tag-seq/DESEQ_output/` holds 53 files and 44 MB: four shrinkage estimators,
each with all-genes, significant and per-gene-count tables, plus eight volcano
PNGs and two MA-plot formats per tissue. The manuscript uses apeglm only.

- [ ] Keep the unshrunken and apeglm tables, the gene-count summary, the PCA,
      correlation heatmap and one volcano and heatmap per tissue.
- [ ] Either stop writing the `normal` and `ashr` tables and the per-estimator
      single-gene-count tables, or write them to an untracked `alternatives/`
      subfolder. Say in notebook 02 that the estimators were compared and the
      significant sets were identical.
- [ ] Drop the duplicate MA-plot format and the per-estimator volcano PNGs.
- [ ] Rebaseline `check-reproduction.R` on the reduced set.

### D3. Move the inputs nothing reads

Already recorded as open decisions in `tag-seq/data/README.md` and
`tag-seq/genome/README.md`; close them.

- [ ] Move `transcript_count_matrix-{gonad,liver}.csv` and
      `onerka_merged-liver.gtf` (33 MB) to the Gannet project folder or into
      the SRA/GEO deposit, and record the URL in `tag-seq/data/README.md`.
- [ ] Drop `Onerka_LOCID_gene_table.txt` (3.8 MB, superseded) and record in
      `tag-seq/genome/README.md` that the feature table is a strict superset.
- [ ] Tracked content then falls from ~129 MB to ~55 MB. Git history keeps the
      old blobs; that is fine, Zenodo archives the tree.

### D4. Write the notebooks for a reader, not an auditor

The notebooks, the directory READMEs and `_common.R` carry the audit narrative
("finding R5", "replaces the .Rmd which…", what the 2023 code did wrong). That
record belongs in `REPRODUCIBILITY-PLAN.md`, which already holds it.

- [ ] Rewrite the prose in notebooks 02–04 and `_common.R` to describe the
      analysis as it is; move each "finding" reference and each comparison
      with the deleted code into the plan document, keyed by finding number.
- [ ] Same for `tag-seq/data/README.md`, `tag-seq/genome/README.md`,
      `tag-seq/sequences/README.md` and `figures/README.md`.
- [ ] Remove the callouts in `index.qmd` that mark the gonad counts as
      provisional and the raw data as undeposited — by resolving A3 and A5,
      not by deleting the text.

### D5. Empty directories and lab logistics

- [ ] `tag-seq/QC/`: commit the MultiQC reports and a per-sample alignment
      table (A5), or remove the placeholder directories. An empty tracked
      directory asserts content that is not there.
- [ ] Move the sequencing logistics in `README.md` (shipping dates, GSAF
      quote, sample manifest, Dropbox links, GitHub issue links) to a
      `NOTES.md` or drop them from the public archive. Keep the Gannet URL.
- [ ] Add a directory map to `README.md`: one line per top-level directory
      saying what it holds and which notebook reads or writes it.

### D6. Figures and supplement as outputs

- [ ] Replace `figures/figure_X.pptx` and its PNG export with the output of
      the figures notebook (C2). Delete the pptx once the scripted figure
      matches.
- [ ] Have the same notebook write `manuscript/supplementary/` (tables S1–Sn
      from A5, B3, C3) so the supplement is regenerated with the results.
- [ ] Add `manuscript/manuscript.qmd` to `render-all.sh` and to the render
      workflow (C4) so the docx and the supplement are built in CI.

### D7. Standard files

- [ ] `LICENSE` (A4).
- [ ] `CITATION.cff` (A4).
- [ ] `tag-seq/` is an extra directory level left from when the repository
      held other work. Flattening it touches every path and every committed
      result location; do it only if the results are being regenerated anyway
      for B1 and D1–D2, and otherwise leave it.

---

## E. Housekeeping

- [ ] `project-sockeye-tagseq.Rproj` has an uncommitted `ProjectId` line added
      by RStudio; commit or discard.
- [ ] Update `index.qmd` and `README.md` once accessions and the DOI exist,
      and remove the "no archival accession yet" callouts.
- [ ] After the Zenodo release, record the DOI in `CITATION.cff`, the
      manuscript, and `README.md`.
