#' Synthetic clinical cohort for examples and tests
#'
#' A small made-up data set with the shape of a routine hospital export: one row
#' per patient, a three-level severity group, baseline demographics, a handful
#' of laboratory values, and a survival outcome. It exists so that every example
#' in this package runs offline and so that `describe_by_group()` and
#' `cox_univariable()` have something to chew on.
#'
#' The values are simulated. Nothing here corresponds to a real person, and the
#' data set must not be used for any substantive analysis.
#'
#' @format A data frame with 24 rows and 15 variables:
#' \describe{
#'   \item{id}{Patient identifier, `P01` to `P24`.}
#'   \item{group}{Severity group: `Control`, `Mild` or `Severe`.}
#'   \item{age}{Age in years.}
#'   \item{sex}{`Female` or `Male`.}
#'   \item{bmi}{Body mass index, kg/m2.}
#'   \item{sbp}{Systolic blood pressure, mmHg.}
#'   \item{dbp}{Diastolic blood pressure, mmHg.}
#'   \item{plt}{Platelet count, 10^9/L.}
#'   \item{wbc}{White blood cell count, 10^9/L.}
#'   \item{alt}{Alanine aminotransferase, U/L.}
#'   \item{ast}{Aspartate aminotransferase, U/L.}
#'   \item{cr}{Creatinine, umol/L.}
#'   \item{glu}{Fasting glucose, mmol/L.}
#'   \item{os_time}{Follow-up time in days.}
#'   \item{os_status}{Event indicator, 1 = death, 0 = censored.}
#' }
#'
#' @source Simulated by `data-raw/demo_clinical.R`.
#'
#' @family bundled data
#' @examples
#' str(demo_clinical)
#' table(demo_clinical$group)
"demo_clinical"

#' A small gene annotation table
#'
#' A hand-curated lookup table used in the examples. It shows the pattern for
#' any modest reference table you want to ship with the package: a few hundred
#' rows, plain columns, no row names.
#'
#' @format A data frame with 12 rows and 4 variables:
#' \describe{
#'   \item{gene}{HGNC symbol.}
#'   \item{chromosome}{Chromosome band.}
#'   \item{family}{Short functional label.}
#'   \item{note}{Free-text remark.}
#' }
#'
#' @source Compiled by hand in `data-raw/gene_panel.R`.
#'
#' @family bundled data
#' @examples
#' gene_panel[gene_panel$family == "immunoglobulin", ]
"gene_panel"
