test_that("timemoir works", {
  result <- timemoir(Sys.sleep(1), Sys.sleep())

  expect_equal(result$fname[[1]], "Sys.sleep(1)")
  expect_lte(result$duration[[1]] - 1, 0.01)
  expect_true(is.na(result$error[[1]]))
  expect_snapshot(result$error[[1]])

  expect_equal(result$fname[[2]], "Sys.sleep()")
  expect_snapshot(result$error[[2]])
})
