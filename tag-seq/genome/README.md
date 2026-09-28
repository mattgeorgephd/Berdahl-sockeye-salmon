# tag-seq/genome

Annotation resources for *Oncorhynchus nerka* assembly
[GCF_006149115.2 (Oner_1.1)](https://www.ncbi.nlm.nih.gov/datasets/genome/GCF_006149115.2/).
Written to close finding E11.

| File | Size | Role | Read by |
|---|---|---|---|
| `GCF_006149115.2_Oner_1.1_feature_table.txt` | 34 MB | **input** — gene symbols, descriptions, GeneIDs and mRNA intervals; source of both the annotation join and goseq's gene lengths | `04` via `load_gene_annotation()` |
| `GCF_006149115.2_Oner_1.1_gene_ontology.gaf.gz` | 1.5 MB | **input** — NCBI GO annotation: 155,362 annotations over 32,629 genes and 6,937 terms | `04` |
| `kegg_one_gene2pathway.tsv` | 859 KB | **input** — KEGG gene-to-pathway map, organism `one` | `04` |
| `kegg_one_pathways.tsv` | 14 KB | **input** — KEGG pathway names | `04` |
| `kegg_one_SOURCE.txt` | 323 B | provenance — REST URLs and retrieval date for the two files above | humans |
| `Onerka_LOCID_gene_table.txt` | 3.8 MB | **superseded** — the pre-2026 annotation table | nothing |

All four input files are checksummed in `CHECKSUMS.sha256` and verified at the
start of every render.

## On Onerka_LOCID_gene_table.txt

It is keyed entirely by LOC identifiers, covering 33,210 of our 37,942 genes, so
it can never annotate a symbol-named gene — which is what produced the fabricated
`LOCNA.*` identifiers of finding R8. The feature table covers 37,929 genes and
agrees with this table on every one of the 33,210 they share, so it is a strict
superset rather than a different annotation. Retained as the record of what the
2023 analysis was annotated against; not read by any notebook. **Open decision:**
keep as provenance or drop.
