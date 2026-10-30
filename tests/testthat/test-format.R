test_that("fmt_p uses the < threshold and keeps NAs", {
  expect_equal(fmt_p(0.0321), "0.032")
  expect_equal(fmt_p(0.00004), "<0.001")
  expect_equal(fmt_p(0.00004, digits = 4), "<0.0001")
  expect_equal(fmt_p(NA_real_), NA_character_)
  expect_equal(fmt_p(c(0.5, 1e-08)), c("0.500", "<0.001"))
})

test_that("fmt_num trims trailing zeros", {
  expect_equal(fmt_num(1.5, 2), "1.5")
  expect_equal(fmt_num(3, 2), "3")
  expect_equal(fmt_num(1.234, 1), "1.2")
  expect_equal(fmt_num(1234.5, 1, big.mark = ","), "1,234.5")
  expect_equal(fmt_num(NA_real_), NA_character_)
})

test_that("fmt_est_ci builds an en dash interval", {
  expect_equal(fmt_est_ci(1.47, 1.11, 1.94), "1.47 (1.11\u20131.94)")
  expect_equal(fmt_est_ci(c(1, 2), c(0.5, 1.5), c(2, 3), digits = 1),
               c("1 (0.5\u20132)", "2 (1.5\u20133)"))
  expect_true(is.na(fmt_est_ci(NA, 1, 2)))
})

test_that("fmt_est_ci_p switches between = and <", {
  expect_equal(fmt_est_ci_p(1.47, 1.11, 1.94, 0.007),
               "1.47 (1.11\u20131.94), P = 0.007")
  expect_equal(fmt_est_ci_p(2.12, 1.67, 2.69, 1e-05),
               "2.12 (1.67\u20132.69), P < 0.001")
})

test_that("fmt_pct respects digits", {
  expect_equal(fmt_pct(0.125), "12.5%")
  expect_equal(fmt_pct(0.5, digits = 0), "50%")
})
