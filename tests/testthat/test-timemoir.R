test_that("launch_function works when no error", {
  my_fun <- function(sec) {
    Sys.sleep(sec)
    return(TRUE)
  }

  result <- timemoir(my_fun(1))

  expect_equal(result$fname, "my_fun(1)")
  expect(result$duration > 1, "test")
  expect_equal(is.na(result$error), TRUE)
})

test_that("launch_function works even on exception", {
  my_fun <- function(sec) {
    Sys.sleep(sec)
    return(TRUE)
  }

  result <- timemoir(my_fun())

  expect_equal(result$fname, "my_fun()")
  expect_snapshot(result$error)
})
