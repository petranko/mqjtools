#' Cache directory and helpers for large reference resources
#'
#' Large reference files (annotation tables, MSigDB collections, public
#' genomics archives) should not be shipped inside a package: they bloat every
#' install, they are usually redistributed under a licence that does not allow
#' bundling, and they change independently of the code. The alternative used
#' here is a user-level cache that survives package upgrades.
#'
#' `mqj_cache_dir()` returns the cache location and creates it on first use.
#' `mqj_fetch()` downloads a file into that cache once and then reuses it, so
#' downstream code can call it unconditionally on every run. `mqj_cache_list()`
#' reports what is already there.
#'
#' @param create Create the directory if it does not exist.
#' @param url Source URL. Any scheme supported by [utils::download.file()] works.
#' @param name File name to use inside the cache. Defaults to the base name of
#'   `url`.
#' @param overwrite Download again even if the cached copy exists.
#' @param md5 Optional expected MD5 checksum; a mismatch deletes the downloaded
#'   file and raises an error.
#' @param quiet Suppress progress messages.
#' @param dir Cache directory to inspect; defaults to [mqj_cache_dir()].
#'
#' @return `mqj_cache_dir()` returns a length-one character path.
#'   `mqj_fetch()` returns the path to the cached file.
#'   `mqj_cache_list()` returns a data frame with `file`, `size_mb` and
#'   `modified`.
#'
#' @family cache helpers
#' @name mqj_cache
#' @examples
#' mqj_cache_dir()
#' str(mqj_cache_list())
NULL

#' @rdname mqj_cache
#' @export
mqj_cache_dir <- function(create = TRUE) {
  path <- tools::R_user_dir("mqjtools", which = "cache")
  if (create && !dir.exists(path)) {
    dir.create(path, recursive = TRUE, showWarnings = FALSE)
  }
  path
}

#' @rdname mqj_cache
#' @export
mqj_cache_list <- function(dir = mqj_cache_dir(create = FALSE)) {
  if (!dir.exists(dir)) {
    return(data.frame(file = character(0), size_mb = numeric(0),
                      modified = as.POSIXct(character(0))))
  }
  files <- list.files(dir, all.files = FALSE, full.names = TRUE)
  info <- file.info(files)
  out <- data.frame(
    file = basename(files),
    size_mb = round(info$size / 1024^2, 3),
    modified = info$mtime,
    stringsAsFactors = FALSE,
    row.names = NULL
  )
  out[order(-out$size_mb), , drop = FALSE]
}

#' @rdname mqj_cache
#' @export
mqj_fetch <- function(url, name = basename(url), overwrite = FALSE,
                      md5 = NULL, quiet = FALSE) {
  if (!is.character(url) || length(url) != 1L || is.na(url)) {
    stop("`url` must be a single URL.", call. = FALSE)
  }
  dest <- file.path(mqj_cache_dir(), name)

  if (file.exists(dest) && !overwrite) {
    if (!quiet) {
      message("Using cached file: ", dest)
    }
    return(dest)
  }

  tmp <- paste0(dest, ".part")
  on.exit(if (file.exists(tmp)) unlink(tmp), add = TRUE)
  utils::download.file(url, destfile = tmp, mode = "wb", quiet = quiet)

  if (!is.null(md5)) {
    got <- unname(tools::md5sum(tmp))
    if (!identical(tolower(got), tolower(md5))) {
      stop("MD5 mismatch for ", name, ": expected ", md5, ", got ", got,
           call. = FALSE)
    }
  }
  if (!file.rename(tmp, dest)) {
    file.copy(tmp, dest, overwrite = TRUE)
  }
  dest
}

#' Path to a file shipped in `inst/extdata`
#'
#' Small reference tables that are genuinely needed at run time, and small
#' enough to justify shipping, belong in `inst/extdata`. This wrapper keeps the
#' call site short and fails loudly when a file is missing, instead of returning
#' an empty string.
#'
#' @param file File name inside `inst/extdata`.
#'
#' @return The full path, as a length-one character vector.
#'
#' @family cache helpers
#' @export
#' @examples
#' mqj_extdata("README.txt")
mqj_extdata <- function(file) {
  path <- system.file("extdata", file, package = "mqjtools", mustWork = FALSE)
  if (!nzchar(path)) {
    stop("File not found in inst/extdata: ", file, call. = FALSE)
  }
  path
}
