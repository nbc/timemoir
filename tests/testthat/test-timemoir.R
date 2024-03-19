test_that("launch_function works when no error", {
  my_fun <- function(sec) {
    Sys.sleep(sec)
    return(TRUE)
  }

  result <- timemoir(my_fun(1))

  expect_equal(result$result, TRUE)
  expect_null(result$error)
  expect(result$duration > 1, "test")
})

test_that("launch_function works even on exception", {
  my_fun <- function(sec) {
    Sys.sleep(sec)
    return(TRUE)
  }

  result <- timemoir(my_fun())

  expect_null(result$result)
  expect_s3_class(result$error, 'error')
})
