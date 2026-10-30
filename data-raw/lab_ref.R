# Internal lookup table -------------------------------------------------------
# Run from the package root:  Rscript data-raw/lab_ref.R
#
# Internal data goes to R/sysdata.rda instead of data/. It is loaded with the
# namespace, is not listed by data(), and cannot be shadowed by a user object
# of the same name. That is the right place for small constants that functions
# need but users should not be editing.

lab_ref <- data.frame(
  analyte = c("plt", "wbc", "alt", "ast", "cr", "glu", "sbp", "dbp", "bmi"),
  low  = c(125, 3.5, 0, 0, 41, 3.9, 90, 60, 18.5),
  high = c(350, 9.5, 40, 40, 111, 6.1, 139, 89, 23.9),
  unit = c("10^9/L", "10^9/L", "U/L", "U/L", "umol/L", "mmol/L",
           "mmHg", "mmHg", "kg/m2"),
  stringsAsFactors = FALSE
)

save(lab_ref, file = "R/sysdata.rda", compress = "xz", version = 2)
