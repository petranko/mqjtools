#' Format numbers, p-values and confidence intervals for reporting
#'
#' These helpers exist because the same few formatting decisions are made in
#' every manuscript: how many decimals, when to write `<0.001`, and which dash
#' to use inside a confidence interval. Keeping them in one place makes the
#' numbers in a table and the numbers in the running text agree by
#' construction, and stops the en dash from silently turning into a hyphen when
#' a file passes through Excel.
#'
#' All functions are vectorised and return `NA_character_` where the input is
#' missing, so they can be used directly inside `transform()` or `within()`.
#'
#' @param x,est,lower,upper,p Numeric vectors. `est`, `lower` and `upper` are
#'   recycled to a common length.
#' @param digits Number of decimals to keep.
#' @param trim Drop trailing zeros (`1.500` becomes `1.5`).
#' @param big.mark Thousands separator, e.g. `","`.
#' @param sep String placed between the confidence limits. `NULL`, the default,
#'   means an en dash; pass `"-"` for a plain hyphen.
#' @param scale Multiplier applied before adding `suffix`; `100` turns a
#'   proportion into a percentage.
#' @param suffix Text appended to the formatted number.
#' @param na String used where any component is missing.
#'
#' @return A character vector.
#'
#' @family formatting helpers
#' @examples
#' fmt_p(c(0.0321, 0.00004, NA))
#' fmt_num(c(1.5, 2.25, 3), digits = 2)
#' fmt_est_ci(1.47, 1.11, 1.94)
#' fmt_pct(c(0.125, 0.5), digits = 1)
#' @name format_helpers
NULL

#' @rdname format_helpers
#' @export
fmt_p <- function(p, digits = 3) {
  eps <- 10^(-digits)
  out <- formatC(p, format = "f", digits = digits)
  out[!is.na(p) & p < eps] <- paste0("<", formatC(eps, format = "f", digits = digits))
  out[is.na(p)] <- NA_character_
  out
}

#' @rdname format_helpers
#' @export
fmt_num <- function(x, digits = 3, trim = TRUE, big.mark = "") {
  out <- formatC(x, format = "f", digits = digits, big.mark = big.mark)
  if (trim) {
    out <- sub("(\\.[0-9]*?)0+$", "\\1", out)
    out <- sub("\\.$", "", out)
  }
  out[is.na(x)] <- NA_character_
  out
}

#' @rdname format_helpers
#' @export
fmt_est_ci <- function(est, lower, upper, digits = 2,
                       sep = NULL, na = NA_character_) {
  if (is.null(sep)) {
    sep <- "\u2013"
  }
  n <- max(length(est), length(lower), length(upper))
  if (n == 0L) {
    return(character(0))
  }
  est <- rep_len(est, n)
  lower <- rep_len(lower, n)
  upper <- rep_len(upper, n)
  out <- character(n)
  for (i in seq_len(n)) {
    if (is.na(est[i]) || is.na(lower[i]) || is.na(upper[i])) {
      out[i] <- na
      next
    }
    out[i] <- paste0(
      fmt_num(est[i], digits), " (",
      fmt_num(lower[i], digits), sep, fmt_num(upper[i], digits), ")"
    )
  }
  out
}

#' @rdname format_helpers
#' @export
fmt_pct <- function(x, digits = 1, scale = 100, suffix = "%") {
  paste0(fmt_num(x * scale, digits), suffix)
}

#' Format an effect estimate, its interval and its p-value as one string
#'
#' Produces the shape used in most results sections, for example
#' `"1.47 (1.11-1.94), P = 0.007"` with an en dash in place of the hyphen. The
#' p-value is written as `P < 0.001` when it falls below the display threshold,
#' matching the convention already used in [fmt_p()].
#'
#' @param est,lower,upper,p Numeric vectors, recycled to a common length.
#' @param digits,digits_p Decimals for the estimate and for the p-value.
#' @param sep Separator between the confidence limits.
#' @param label Prefix placed before the p-value.
#'
#' @return A character vector.
#'
#' @family formatting helpers
#' @export
#' @examples
#' fmt_est_ci_p(1.47, 1.11, 1.94, 0.007)
#' fmt_est_ci_p(2.12, 1.67, 2.69, 1e-05)
fmt_est_ci_p <- function(est, lower, upper, p, digits = 2, digits_p = 3,
                         sep = NULL, label = "P = ") {
  ci <- fmt_est_ci(est, lower, upper, digits = digits, sep = sep)
  pv <- fmt_p(p, digits = digits_p)
  pv <- ifelse(grepl("^<", pv), sub("^<", "P < ", pv), paste0(label, pv))
  out <- paste0(ci, ", ", pv)
  out[is.na(ci)] <- NA_character_
  out
}
