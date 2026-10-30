#' Read a table without thinking about its format
#'
#' Dispatches on the file extension so the calling code never has to remember
#' whether a file is `.csv`, `.tsv`, `.xlsx` or `.rds`. Column names are kept
#' verbatim (`check.names = FALSE`) because clinical exports routinely contain
#' spaces, Chinese characters and duplicated names that R would otherwise
#' mangle.
#'
#' @param path Path to the file. Must exist.
#' @param sheet Sheet name or index; only used for spreadsheet input.
#' @param ... Passed on to the underlying reader.
#'
#' @return A `data.frame`, or whatever object was stored for `.rds` input.
#'   For `.rda`/`.RData` files a named list of the objects they contain.
#'
#' @export
#' @examples
#' f <- tempfile(fileext = ".csv")
#' write.csv(data.frame(a = 1:3, b = c("x", "y", "z")), f, row.names = FALSE)
#' read_any(f)
read_any <- function(path, sheet = 1, ...) {
  if (!file.exists(path)) {
    stop("File not found: ", path, call. = FALSE)
  }
  ext <- tolower(tools::file_ext(path))
  dot <- list(...)

  if (ext %in% c("csv")) {
    args <- utils::modifyList(list(file = path, check.names = FALSE), dot)
    return(do.call(utils::read.csv, args))
  }
  if (ext %in% c("tsv", "txt")) {
    args <- utils::modifyList(
      list(file = path, check.names = FALSE, sep = "\t"), dot
    )
    return(do.call(utils::read.delim, args))
  }
  if (ext %in% c("xlsx", "xls")) {
    if (!requireNamespace("readxl", quietly = TRUE)) {
      stop("Package 'readxl' is needed for spreadsheet input.", call. = FALSE)
    }
    out <- do.call(
      readxl::read_excel,
      utils::modifyList(list(path = path, sheet = sheet), dot)
    )
    return(as.data.frame(out))
  }
  if (ext %in% c("rds")) {
    return(readRDS(path))
  }
  if (ext %in% c("rda", "rdata")) {
    env <- new.env(parent = emptyenv())
    load(path, envir = env)
    return(as.list(env, all.names = TRUE))
  }
  stop(
    "Unsupported extension '.", ext, "'. Supported: csv, tsv, txt, xlsx, xls, rds, rda.",
    call. = FALSE
  )
}


#' Write a publication-ready workbook
#'
#' Writes one or more data frames to an `.xlsx` file using a deliberately plain
#' house style: Times New Roman, thin full borders, bold centred header, frozen
#' header row, no fill colours. That combination survives most journal
#' production systems without further editing, and stays readable when a
#' reviewer prints it in black and white.
#'
#' Formatting is applied to values only. Pre-format numbers as character with
#' [fmt_p()] or [fmt_est_ci()] when you need `"<0.001"` or an en dash in a
#' confidence interval, because a cell can hold either a number or a string,
#' not both.
#'
#' @param x A data frame, or a named list of data frames (one worksheet each).
#' @param path Output path; the directory is created if needed.
#' @param font,size Font family and point size applied to the whole workbook.
#' @param digits Numeric columns are rounded to this many decimals. Use `NULL`
#'   to leave numbers untouched.
#' @param na String used for missing values.
#' @param freeze Freeze the header row.
#' @param autofilter Add an autofilter to the header row.
#' @param overwrite Allow replacing an existing file.
#'
#' @return The output path, invisibly.
#'
#' @export
#' @examples
#' \dontrun{
#' write_xlsx_pub(
#'   list(Cohort = head(iris), Models = head(mtcars)),
#'   tempfile(fileext = ".xlsx")
#' )
#' }
write_xlsx_pub <- function(x, path, font = "Times New Roman", size = 10,
                           digits = 3, na = "", freeze = TRUE,
                           autofilter = FALSE, overwrite = TRUE) {
  if (!requireNamespace("openxlsx", quietly = TRUE)) {
    stop("Package 'openxlsx' is needed to write xlsx files.", call. = FALSE)
  }
  if (file.exists(path) && !overwrite) {
    stop("File exists and overwrite = FALSE: ", path, call. = FALSE)
  }
  ensure_dir(dirname(path))

  sheets <- if (is.data.frame(x)) stats::setNames(list(x), "Sheet1") else x
  if (!is.list(sheets) || is.null(names(sheets))) {
    stop("`x` must be a data frame or a named list of data frames.", call. = FALSE)
  }

  header_style <- openxlsx::createStyle(
    fontName = font, fontSize = size, textDecoration = "bold",
    halign = "center", valign = "center", wrapText = TRUE,
    border = "TopBottomLeftRight", borderStyle = "thin"
  )
  body_style <- openxlsx::createStyle(
    fontName = font, fontSize = size, valign = "center",
    border = "TopBottomLeftRight", borderStyle = "thin"
  )

  wb <- openxlsx::createWorkbook()
  for (nm in names(sheets)) {
    df <- as.data.frame(sheets[[nm]])
    if (!is.null(digits)) {
      num <- vapply(df, is.numeric, logical(1))
      df[num] <- lapply(df[num], round, digits = digits)
    }
    openxlsx::addWorksheet(wb, nm)
    openxlsx::writeData(wb, nm, df, headerStyle = header_style,
                        keepNA = FALSE, na.string = na)
    nr <- nrow(df) + 1L
    nc <- max(ncol(df), 1L)
    openxlsx::addStyle(wb, nm, body_style, rows = 2:nr, cols = 1:nc,
                       gridExpand = TRUE, stack = FALSE)
    openxlsx::setColWidths(wb, nm, cols = 1:nc, widths = "auto")
    if (freeze) openxlsx::freezePane(wb, nm, firstRow = TRUE)
    if (autofilter && nrow(df) > 0L) {
      openxlsx::addFilter(wb, nm, row = 1, cols = 1:nc)
    }
  }
  openxlsx::saveWorkbook(wb, path, overwrite = TRUE)
  invisible(path)
}


#' Write a tab-delimited file for reproducible archives
#'
#' Plain text, no quoting, no row names, `NA` written as an empty field. This is
#' the format to use for anything that will be read back months later, or handed
#' to a collaborator: it diffs cleanly in git and opens in Excel without
#' mangling.
#'
#' @param x A data frame.
#' @param path Output path; the directory is created if needed.
#' @param na String used for missing values.
#' @param overwrite Allow replacing an existing file.
#'
#' @return The output path, invisibly.
#'
#' @export
#' @examples
#' f <- tempfile(fileext = ".tsv")
#' write_tsv_pub(head(iris), f)
#' file.exists(f)
write_tsv_pub <- function(x, path, na = "NA", overwrite = TRUE) {
  if (file.exists(path) && !overwrite) {
    stop("File exists and overwrite = FALSE: ", path, call. = FALSE)
  }
  ensure_dir(dirname(path))
  utils::write.table(
    x, file = path, sep = "\t", quote = FALSE, row.names = FALSE,
    na = na, fileEncoding = "UTF-8"
  )
  invisible(path)
}


#' Create a directory if it does not exist
#'
#' @param path Directory path.
#'
#' @return The path, invisibly.
#' @export
#' @examples
#' ensure_dir(file.path(tempdir(), "demo_dir"))
ensure_dir <- function(path) {
  if (length(path) == 0L || is.na(path) || identical(path, ".")) {
    return(invisible(path))
  }
  if (!dir.exists(path)) dir.create(path, recursive = TRUE, showWarnings = FALSE)
  invisible(path)
}


#' Default value for `NULL`
#'
#' @param x,y If `x` is `NULL`, `y` is returned; otherwise `x`.
#'
#' @return `x` or `y`.
#' @keywords internal
#' @noRd
`%||%` <- function(x, y) if (is.null(x)) y else x
