#' mqjtools: a personal toolkit for clinical and bioinformatics work
#'
#' The package collects the helper functions that were previously copy-pasted
#' between projects: file input and output, regression reporting, figure
#' styling, and a lightweight cache layer for reference resources that are too
#' large, or too restrictive in their licence, to ship inside the package.
#'
#' @section Design rules:
#' * Heavy dependencies (`ggplot2`, `openxlsx`, `readxl`, `data.table`,
#'   `survival`) live in `Suggests` and are guarded with [requireNamespace()].
#'   The package therefore installs on a bare R installation.
#' * Anything larger than roughly one megabyte does **not** go into `data/`.
#'   It is registered through [mqj_fetch()] and lives in a user-level cache.
#' * Every exported function is documented with an example that runs offline.
#'
#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @importFrom stats qnorm qt var
#' @importFrom tools file_ext md5sum
#' @importFrom utils download.file modifyList read.csv read.delim
## usethis namespace: end
NULL
