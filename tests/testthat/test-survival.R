test_that("cox_tidy returns one row per term", {
  skip_if_not_installed("survival")
  fit <- survival::coxph(survival::Surv(os_time, os_status) ~ age, data = demo_clinical)
  out <- cox_tidy(fit)
  expect_equal(nrow(out), 1L)
  expect_equal(names(out), c("term", "hr", "conf.low", "conf.high",
                             "se", "z", "p", "n", "events"))
  expect_true(out$conf.low < out$hr && out$hr < out$conf.high)
})

test_that("cox_tidy rejects non-coxph input", {
  expect_error(cox_tidy(stats::lm(mpg ~ wt, data = mtcars)), "coxph")
})

test_that("cox_univariable stacks models and keeps the variable name", {
  skip_if_not_installed("survival")
  out <- cox_univariable(demo_clinical, "os_time", "os_status",
                         c("age", "sex", "group"))
  expect_equal(unique(out$variable), c("age", "sex", "group"))
  expect_equal(sum(out$variable == "group"), 2L)  # three levels, two contrasts
  expect_true(all(out$n == nrow(demo_clinical)))
})

test_that("cox_univariable returns NA rows instead of failing", {
  skip_if_not_installed("survival")
  d <- demo_clinical
  d$constant <- 1
  out <- cox_univariable(d, "os_time", "os_status", "constant")
  expect_true(is.na(out$hr))
})

test_that("cox_univariable validates column names", {
  skip_if_not_installed("survival")
  expect_error(
    cox_univariable(demo_clinical, "os_time", "os_status", "nope"),
    "not found"
  )
})
