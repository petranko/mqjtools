test_that("describe_by_group returns one block per variable", {
  out <- describe_by_group(demo_clinical, vars = c("age", "sex"), by = "group")
  expect_s3_class(out, "data.frame")
  expect_equal(names(out), c("Variable", "Level", "Control", "Mild", "Severe", "Overall"))
  expect_equal(sum(out$Variable == "sex"), 2L)   # two levels
  expect_equal(sum(out$Variable == "age"), 1L)   # continuous: one row
  expect_true(all(grepl("^[0-9.]+ \\([0-9.]+\\)$", out$Overall[out$Variable == "age"])))
})

test_that("describe_by_group uses median (IQR) when asked", {
  out <- describe_by_group(demo_clinical, vars = "plt", by = "group",
                           median_vars = "plt")
  expect_match(out$Overall, "^[0-9.]+ \\([0-9.]+, [0-9.]+\\)$")
})

test_that("describe_by_group adds a p-value column", {
  out <- describe_by_group(demo_clinical, vars = c("age", "sex"), by = "group",
                           p_value = TRUE)
  expect_true("P" %in% names(out))
  expect_true(all(is.na(out$P) | grepl("^<?[0-9.]+$", out$P)))
})

test_that("describe_by_group works without a grouping variable", {
  out <- describe_by_group(demo_clinical, vars = "age")
  expect_equal(names(out), c("Variable", "Level", "Overall"))
})

test_that("describe_by_group rejects unknown columns", {
  expect_error(describe_by_group(demo_clinical, vars = "nope"), "not found")
})
