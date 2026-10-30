# Simulate the example cohort ------------------------------------------------
# Run from the package root:  Rscript data-raw/demo_clinical.R
# The .rda written here is what users see as `demo_clinical`.

set.seed(20261030)

n <- 24
grp <- factor(rep(c("Control", "Mild", "Severe"), length.out = n),
              levels = c("Control", "Mild", "Severe"))
shift <- c(Control = 0, Mild = 6, Severe = 14)[as.character(grp)]

demo_clinical <- data.frame(
  id     = sprintf("P%02d", seq_len(n)),
  group  = grp,
  age    = round(stats::rnorm(n, 58, 12)),
  sex    = factor(sample(c("Female", "Male"), n, replace = TRUE),
                  levels = c("Female", "Male")),
  bmi    = round(stats::rnorm(n, 24, 3.2), 1),
  sbp    = round(stats::rnorm(n, 122 + shift, 14)),
  dbp    = round(stats::rnorm(n, 76 + shift / 3, 10)),
  plt    = round(pmax(stats::rnorm(n, 190 - 3 * shift, 45), 18)),
  wbc    = round(pmax(stats::rnorm(n, 6.1 + shift / 8, 1.7), 1.2), 2),
  alt    = round(pmax(stats::rlnorm(n, 3.1, 0.45), 3)),
  ast    = round(pmax(stats::rlnorm(n, 3.2, 0.45), 3)),
  cr     = round(pmax(stats::rnorm(n, 76, 18), 35), 1),
  glu    = round(pmax(stats::rnorm(n, 5.5, 0.8), 3.5), 2),
  os_time   = round(stats::rexp(n, rate = 1 / 200), 1),
  os_status = stats::rbinom(n, 1, plogis(-1.2 + shift / 10)),
  stringsAsFactors = FALSE
)

# A couple of missing values, because real exports always have some and the
# examples should show that the helpers cope with them.
demo_clinical$plt[c(5, 17)] <- NA
demo_clinical$alt[9] <- NA

save(demo_clinical, file = "data/demo_clinical.rda", compress = "xz", version = 2)
