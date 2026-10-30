test_that("lab_ref_range returns the stored interval", {
  out <- lab_ref_range("plt")
  expect_equal(out$low, 125)
  expect_equal(out$high, 350)
  expect_equal(out$unit, "10^9/L")
})

test_that("lab_ref_range is case insensitive and vectorised", {
  out <- lab_ref_range(c("PLT", "wbc"))
  expect_equal(nrow(out), 2L)
  expect_false(any(is.na(out$high)))
})

test_that("lab_ref_range returns NA for unknown analytes", {
  out <- lab_ref_range("nope")
  expect_true(is.na(out$low))
})
