# figures

**Manuscript-only. Not produced by any script in this repository** (finding E11).

| File | Size | Provenance |
|---|---|---|
| `figure_X.png` | 846 KB | exported from `figure_X.pptx` |
| `figure_X.pptx` | 1.5 MB | hand-assembled; no producing code |

Every figure the analysis generates is written by the notebooks into
`tag-seq/DESEQ_output/<tissue>/` (PCA, heatmaps, volcano and MA plots) or
`tag-seq/GO_output/<tissue>/`. This directory is a hand-built manuscript
composite, and the `.pptx` is its only source.

**Open decision:** if any panel of `figure_X` is a rendered result, regenerate
that panel from a notebook chunk so it tracks the data. Otherwise this note is
the resolution — it is a figure, not a result, and the repository does not claim
to reproduce it.
