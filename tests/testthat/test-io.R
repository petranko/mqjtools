test_that("read_any dispatches on extension", {
  f <- tempfile(fileext = ".csv")
  on.exit(unlink(f), add = TRUE)
  utils::write.csv(data.frame(a = 1:3, b = c("x", "y", "z")), f, row.names = FALSE)
  out <- read_any(f)
  expect_s3_class(out, "data.frame")
  expect_equal(nrow(out), 3L)
  expect_equal(names(out), c("a", "b"))
})

test_that("read_any keeps column names verbatim", {
  f <- tempfile(fileext = ".csv")
  on.exit(unlink(f), add = TRUE)
  utils::write.csv(data.frame(a = 1, b = 2, check.names = FALSE), f, row.names = FALSE)
  dat <- data.frame("age (years)" = 1, "ALT U/L" = 2, check.names = FALSE)
  utils::write.csv(dat, f, row.names = FALSE)
  expect_equal(names(read_any(f)), c("age (years)", "ALT U/L"))
})

test_that("read_any errors informatively", {
  expect_error(read_any("does-not-exist.csv"), "File not found")
  f <- tempfile(fileext = ".xyz")
  on.exit(unlink(f), add = TRUE)
  writeLines("x", f)
  expect_error(read_any(f), "Unsupported extension")
})

test_that("write_tsv_pub writes a header and respects overwrite", {
  f <- tempfile(fileext = ".tsv")
  on.exit(unlink(f), add = TRUE)
  out <- write_tsv_pub(head(iris), f)
  expect_equal(out, f)
  expect_equal(length(readLines(f)), 7L)
  expect_error(write_tsv_pub(head(iris), f, overwrite = FALSE), "overwrite")
})

test_that("ensure_dir creates nested directories", {
  d <- file.path(tempdir(), "mqjtools_test", "a", "b")
  on.exit(unlink(file.path(tempdir(), "mqjtools_test"), recursive = TRUE), add = TRUE)
  ensure_dir(d)
  expect_true(dir.exists(d))
  expect_silent(ensure_dir(d))
})
