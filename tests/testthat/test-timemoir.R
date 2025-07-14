test_that("timemoir works", {
  result <- timemoir(Sys.sleep(1), Sys.sleep(), verbose = FALSE)

  expect_s3_class(object = result, class = "timemoir")
  expect_s3_class(object = result, class = "tbl")

  expect_equal(nrow(result), 2)
  expect_named(result, c("fname", "duration", "error", "start_mem", "max_mem", "cpu_user", "cpu_sys"))

  expect_equal(result$fname[[1]], "Sys.sleep(1)")
  expect_lte(result$duration[[1]] - 1, 0.2)
  expect_true(is.na(result$error[[1]]))
  expect_snapshot(result$error[[1]])

  expect_equal(result$fname[[2]], "Sys.sleep()")
  expect_snapshot(result$error[[2]])

  expect_error(timemoir(Sys.sleep(1), verbose = "a"))
  expect_error(timemoir(Sys.sleep(1), interval = "a"))

  result <- timemoir(Sys.sleep(1), Sys.sleep(), verbose = FALSE, n = 2)

  expect_equal(nrow(result), 4)
})

test_that("as_timemoir works", {
  object <- as_timemoir(tibble::tibble())
  expect_s3_class(object = object, class = "timemoir")
})

test_that("timemoir works when wrapper is killed", {
  test_fun <- function() {
    Sys.sleep(1)
    ps::ps_kill(ps::ps_handle(Sys.getpid()))
  }
  result <- timemoir(test_fun())
  expect_s3_class(object = result, class = "tbl")
  expect_true(nzchar(result$error))
})

test_that("timemoir verbosity", {
  expect_silent(result <- timemoir(Sys.sleep(1), Sys.sleep(), verbose = FALSE))
})

test_that("test wrapper", {
  file <- tempfile()
  wrapper("truc", parse(text = "Sys.sleep(1)"), flag_file = file)
  expect_true(file.exists(file))

  file <- tempfile()
  wrapper("truc", parse(text = "Sys.sleep()"), flag_file = file)
  expect_true(file.exists(file))
})
