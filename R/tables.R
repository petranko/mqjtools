#' Summarise variables by group ("Table 1")
#'
#' Builds the conventional baseline table: one block of rows per variable, a
#' column per group plus an optional overall column, and an optional p-value
#' column. Continuous variables are reported as mean (SD) by default, or as
#' median (IQR) for the variables named in `median_vars`; categorical variables
#' are reported as n (%).
#'
#' The test used for the p-value column follows the summary that was chosen:
#' `t.test` / `aov` for mean (SD) variables, `wilcox.test` / `kruskal.test` for
#' median (IQR) variables, and `chisq.test` for categorical variables. These are
#' descriptive tests only; they do not adjust for anything and should not be
#' read as effect estimates.
#'
#' @param data A data frame.
#' @param vars Character vector of variable names to summarise.
#' @param by Optional single grouping variable name. When `NULL` only the
#'   overall column is produced.
#' @param median_vars Character vector of continuous variables to summarise as
#'   median (IQR). Variables not listed are summarised as mean (SD).
#' @param digits Decimals for continuous summaries and percentages.
#' @param p_value Add a p-value column comparing the groups.
#' @param overall Add an overall column even when `by` is given.
#' @param na.rm Drop missing values before summarising; the denominator for
#'   percentages is then the number of non-missing observations.
#'
#' @return A data frame with columns `Variable`, `Level`, one column per group,
#'   `Overall` (when requested) and `P` (when requested).
#'
#' @family descriptive helpers
#' @export
#' @examples
#' describe_by_group(
#'   demo_clinical,
#'   vars = c("age", "sex", "plt"),
#'   by = "group",
#'   median_vars = "plt",
#'   p_value = TRUE
#' )
describe_by_group <- function(data, vars, by = NULL, median_vars = NULL,
                              digits = 1, p_value = FALSE, overall = TRUE,
                              na.rm = TRUE) {
  if (!is.data.frame(data)) {
    stop("`data` must be a data frame.", call. = FALSE)
  }
  missing_vars <- setdiff(c(vars, by), names(data))
  if (length(missing_vars) > 0L) {
    stop("Column(s) not found in `data`: ", paste(missing_vars, collapse = ", "),
         call. = FALSE)
  }

  if (is.null(by)) {
    idx <- list(Overall = seq_len(nrow(data)))
    groups <- "Overall"
  } else {
    g <- data[[by]]
    if (na.rm) {
      keep <- !is.na(g)
      data <- data[keep, , drop = FALSE]
      g <- g[keep]
    }
    lv <- if (is.factor(g)) levels(droplevels(as.factor(g))) else sort(unique(as.character(g)))
    idx <- lapply(lv, function(k) which(as.character(g) == k))
    names(idx) <- lv
    groups <- lv
  }

  fmt_cont <- function(v, med) {
    v <- v[!is.na(v)]
    if (length(v) == 0L) {
      return(NA_character_)
    }
    if (med) {
      q <- stats::quantile(v, c(0.5, 0.25, 0.75), names = FALSE, type = 7)
      paste0(fmt_num(q[1], digits), " (", fmt_num(q[2], digits), ", ",
             fmt_num(q[3], digits), ")")
    } else {
      paste0(fmt_num(mean(v), digits), " (", fmt_num(stats::sd(v), digits), ")")
    }
  }

  rows <- list()
  for (v in vars) {
    x <- data[[v]]
    med <- v %in% median_vars
    if (is.numeric(x)) {
      cells <- vapply(idx, function(i) fmt_cont(x[i], med), character(1))
      rows[[length(rows) + 1L]] <- data.frame(
        Variable = v, Level = "", as.list(cells), check.names = FALSE,
        stringsAsFactors = FALSE
      )
    } else {
      xc <- as.character(x)
      lv <- if (is.factor(x)) levels(droplevels(as.factor(x))) else sort(unique(xc[!is.na(xc)]))
      for (k in lv) {
        cells <- vapply(idx, function(i) {
          xi <- xc[i]
          xi <- xi[!is.na(xi)]
          n <- sum(xi == k)
          if (length(xi) == 0L) {
            return(NA_character_)
          }
          paste0(n, " (", fmt_num(100 * n / length(xi), digits, trim = FALSE), ")")
        }, character(1))
        rows[[length(rows) + 1L]] <- data.frame(
          Variable = v, Level = k, as.list(cells), check.names = FALSE,
          stringsAsFactors = FALSE
        )
      }
    }
  }

  out <- do.call(rbind, rows)
  names(out)[-(1:2)] <- groups
  if (overall && !"Overall" %in% names(out)) {
    all_cells <- character(nrow(out))
    for (r in seq_len(nrow(out))) {
      v <- out$Variable[r]
      x <- data[[v]]
      if (is.numeric(x)) {
        all_cells[r] <- fmt_cont(x, v %in% median_vars)
      } else {
        xc <- as.character(x)
        xc <- xc[!is.na(xc)]
        n <- sum(xc == out$Level[r])
        all_cells[r] <- if (length(xc) == 0L) NA_character_ else
          paste0(n, " (", fmt_num(100 * n / length(xc), digits, trim = FALSE), ")")
      }
    }
    out$Overall <- all_cells
  }

  if (p_value && !is.null(by)) {
    pv <- rep(NA_real_, nrow(out))
    for (v in vars) {
      x <- data[[v]]
      sel <- out$Variable == v
      if (is.numeric(x)) {
        g <- as.factor(data[[by]])
        ok <- !is.na(x)
        pv[sel] <- tryCatch({
          if (nlevels(g) == 2L) {
            if (v %in% median_vars) {
              stats::wilcox.test(x[ok] ~ g[ok])$p.value
            } else {
              stats::t.test(x[ok] ~ g[ok])$p.value
            }
          } else {
            if (v %in% median_vars) {
              stats::kruskal.test(x[ok] ~ g[ok])$p.value
            } else {
              stats::anova(stats::lm(x[ok] ~ g[ok]))[["Pr(>F)"]][1]
            }
          }
        }, error = function(e) NA_real_)
      } else {
        pv[sel] <- tryCatch({
          tb <- table(data[[v]], data[[by]])
          if (any(dim(tb) < 2L)) NA_real_ else
            suppressWarnings(stats::chisq.test(tb)$p.value)
        }, error = function(e) NA_real_)
      }
    }
    out$P <- fmt_p(pv)
  }

  rownames(out) <- NULL
  out
}
