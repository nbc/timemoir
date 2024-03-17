test_that("multiplication works", {
  my_fun <- function(sec) {
    Sys.sleep(sec)
    return(TRUE)
  }

  result <- launch_function(my_fun(1))

  expect_equal(result$result, TRUE)
  expect_null(result$error)
})

test_that("multiplication works", {
  my_fun <- function(sec) {
    Sys.sleep(sec)
    return(TRUE)
  }

  result <- launch_function(my_fun())

  expect_null(result$result)
  expect_snapshot(result$error)
})
