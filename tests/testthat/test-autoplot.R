test_that("autoplot works", {
  skip_on_cran()
  skip_if_not_installed("ggplot2")
  skip_if_not_installed("tidyr")
  y <- timemoir(Sys.sleep(0.5), Sys.sleep(0.5))
  expect_s3_class(ggplot2::autoplot(y), "ggplot")
  # expect_s3_class(plot(y), "ggplot")
})
