#' Look up a laboratory reference range
#'
#' Returns the reference interval stored in the package's internal table
#' (`R/sysdata.rda`). Internal data like this is the right home for small lookup
#' tables that the user never needs to see: it is loaded with the namespace, it
#' cannot be accidentally overwritten in the global environment, and it does not
#' appear in the list of exported data sets.
#'
#' An unknown analyte returns `NA` rather than an error, so the function can be
#' used inside a loop over whatever columns a file happens to contain.
#'
#' @param analyte Character vector of analyte names, matched case-insensitively
#'   against the internal table (for example `"plt"`, `"wbc"`, `"alt"`).
#' @param sex Optional sex, for analytes with sex-specific intervals. Currently
#'   unused by the bundled table; kept so that the signature does not have to
#'   change later.
#'
#' @return A data frame with one row per input element and columns `analyte`,
#'   `low`, `high` and `unit`.
#'
#' @family descriptive helpers
#' @export
#' @examples
#' lab_ref_range(c("plt", "wbc", "not_an_analyte"))
lab_ref_range <- function(analyte, sex = NULL) {
  key <- tolower(as.character(analyte))
  i <- match(key, tolower(lab_ref$analyte))
  out <- data.frame(
    analyte = as.character(analyte),
    low = lab_ref$low[i],
    high = lab_ref$high[i],
    unit = lab_ref$unit[i],
    stringsAsFactors = FALSE,
    row.names = NULL
  )
  out
}
