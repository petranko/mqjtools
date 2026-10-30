#' Tidy a Cox proportional hazards model
#'
#' Converts a fitted [survival::coxph()] object into a plain data frame with
#' one row per model term, which is usually what a manuscript table needs and
#' what `rbind()` expects when several models are stacked together.
#'
#' Hazard ratios and confidence limits are taken from
#' `summary(fit)$conf.int`; the p-value is the Wald p-value from
#' `summary(fit)$coefficients`. No p-value is invented for terms that could not
#' be estimated.
#'
#' @param fit A `coxph` fit.
#'
#' @return A data frame with columns `term`, `hr`, `conf.low`, `conf.high`,
#'   `se`, `z`, `p`, `n` and `events`.
#'
#' @family survival helpers
#' @export
#' @examples
#' if (requireNamespace("survival", quietly = TRUE)) {
#'   fit <- survival::coxph(
#'     survival::Surv(os_time, os_status) ~ age + group,
#'     data = demo_clinical
#'   )
#'   cox_tidy(fit)
#' }
cox_tidy <- function(fit) {
  if (!inherits(fit, "coxph")) {
    stop("`fit` must be a coxph object.", call. = FALSE)
  }
  s <- summary(fit)
  ci <- s$conf.int
  cf <- s$coefficients
  data.frame(
    term = rownames(cf),
    hr = unname(ci[, "exp(coef)"]),
    conf.low = unname(ci[, "lower .95"]),
    conf.high = unname(ci[, "upper .95"]),
    se = unname(cf[, "se(coef)"]),
    z = unname(cf[, "z"]),
    p = unname(cf[, "Pr(>|z|)"]),
    n = unname(s$n),
    events = unname(s$nevent),
    stringsAsFactors = FALSE,
    row.names = NULL
  )
}

#' Univariable Cox models for a set of variables
#'
#' Fits one [survival::coxph()] model per variable and returns the results
#' stacked in a single data frame, with the variable name kept in a separate
#' column. This is the screening step most clinical papers report before a
#' multivariable model, and the output is shaped so that it can be filtered on
#' `p` and passed straight to [fmt_est_ci()].
#'
#' Models are fitted with `ties = "efron"`, the default in `coxph`. Variables
#' that are constant, or that produce a fit with no estimable coefficient, are
#' returned with `NA` estimates rather than aborting the whole loop.
#'
#' @param data A data frame.
#' @param time Name of the follow-up time column.
#' @param status Name of the event indicator (0/1, or a factor).
#' @param vars Character vector of predictor names. Factors produce one row per
#'   non-reference level.
#' @param ... Further arguments passed to [survival::coxph()].
#'
#' @return A data frame with columns `variable`, `term`, `hr`, `conf.low`,
#'   `conf.high`, `se`, `z`, `p`, `n` and `events`.
#'
#' @family survival helpers
#' @export
#' @examples
#' if (requireNamespace("survival", quietly = TRUE)) {
#'   cox_univariable(
#'     demo_clinical,
#'     time = "os_time", status = "os_status",
#'     vars = c("age", "sex", "group")
#'   )
#' }
cox_univariable <- function(data, time, status, vars, ...) {
  if (!requireNamespace("survival", quietly = TRUE)) {
    stop("Package 'survival' is needed for Cox models.", call. = FALSE)
  }
  missing_vars <- setdiff(c(time, status, vars), names(data))
  if (length(missing_vars) > 0L) {
    stop("Column(s) not found in `data`: ", paste(missing_vars, collapse = ", "),
         call. = FALSE)
  }

  out <- vector("list", length(vars))
  for (i in seq_along(vars)) {
    v <- vars[i]
    f <- stats::as.formula(sprintf("survival::Surv(%s, %s) ~ %s", time, status, v))
    fit <- tryCatch(
      survival::coxph(f, data = data, ...),
      error = function(e) NULL
    )
    if (is.null(fit)) {
      out[[i]] <- data.frame(
        variable = v, term = v, hr = NA_real_, conf.low = NA_real_,
        conf.high = NA_real_, se = NA_real_, z = NA_real_, p = NA_real_,
        n = NA_integer_, events = NA_integer_, stringsAsFactors = FALSE
      )
      next
    }
    tb <- cox_tidy(fit)
    tb$variable <- v
    out[[i]] <- tb[, c("variable", "term", "hr", "conf.low", "conf.high",
                       "se", "z", "p", "n", "events")]
  }
  res <- do.call(rbind, out)
  rownames(res) <- NULL
  res
}
