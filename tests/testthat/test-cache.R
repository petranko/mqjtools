test_that("mqj_cache_dir returns an existing directory", {
  d <- mqj_cache_dir()
  expect_type(d, "character")
  expect_length(d, 1L)
  expect_true(dir.exists(d))
})

test_that("mqj_cache_list always returns a data frame", {
  out <- mqj_cache_list()
  expect_s3_class(out, "data.frame")
  expect_true(all(c("file", "size_mb", "modified") %in% names(out)))
})

test_that("mqj_cache_list copes with a missing directory", {
  out <- mqj_cache_list(file.path(tempdir(), "definitely-not-here-12345"))
  expect_equal(nrow(out), 0L)
})

test_that("mqj_fetch validates its input", {
  expect_error(mqj_fetch(NA_character_), "single URL")
  expect_error(mqj_fetch(c("a", "b")), "single URL")
})

test_that("mqj_extdata finds a shipped file and errors on a missing one", {
  expect_true(file.exists(mqj_extdata("README.txt")))
  expect_error(mqj_extdata("nope.txt"), "not found")
})
