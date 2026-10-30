# Small exported annotation table --------------------------------------------
# Run from the package root:  Rscript data-raw/gene_panel.R

gene_panel <- data.frame(
  gene = c("CKAP2", "TCF19", "MSH2", "RELT", "AQP3", "MZB1",
           "JCHAIN", "IGHA1", "SEC11C", "SSR4", "DERL3", "FKBP11"),
  chromosome = c("13q14", "6p21.33", "2p21", "11q13.4", "9p13.3", "5q31.2",
                 "4q13.3", "14q32.33", "18q21.32", "Xq28", "22q11.23", "12q13.12"),
  family = c("microtubule", "transcription", "DNA repair", "TNF receptor",
             "aquaporin", "ER chaperone", "immunoglobulin", "immunoglobulin",
             "signal peptidase", "translocon", "ERAD", "peptidyl-prolyl isomerase"),
  note = c("spindle assembly", "MHC class I region", "mismatch repair",
           "orphan TNFRSF member", "glycerol and H2O2 transport",
           "plasma cell ER", "Ig J chain", "IgA heavy chain constant region",
           "ER signal peptidase subunit", "TRAP-delta", "ER-associated degradation",
           "ER folding"),
  stringsAsFactors = FALSE
)

save(gene_panel, file = "data/gene_panel.rda", compress = "xz", version = 2)
