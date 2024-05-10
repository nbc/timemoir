test_that("timemoir works", {
  result <- timemoir(Sys.sleep(1), Sys.sleep(), verbose=FALSE)

  expect_equal(nrow(result), 2)
  expect_equal(colnames(result), c('fname', 'duration', 'error', 'start_mem', 'max_mem'))

  expect_equal(result$fname[[1]], "Sys.sleep(1)")
  expect_lte(result$duration[[1]] - 1, 0.2)
  expect_true(is.na(result$error[[1]]))
  expect_snapshot(result$error[[1]])

  expect_equal(result$fname[[2]], "Sys.sleep()")
  expect_snapshot(result$error[[2]])

  expect_error(timemoir(Sys.sleep(1), verbose="a"))
  expect_error(timemoir(Sys.sleep(1), interval="a"))
})

test_that("timemoir verbosity", {
  expect_silent(result <- timemoir(Sys.sleep(1), Sys.sleep(), verbose=FALSE))
  expect_snapshot(result <- timemoir(Sys.sleep(1.9), Sys.sleep()))
})

test_that("test wrapper", {
  file <- tempfile()
  wrapper("truc", parse(text="Sys.sleep(1)"), flag_file=file)
  expect_true(file.exists(file))

  file <- tempfile()
  wrapper("truc", parse(text="Sys.sleep()"), flag_file=file)
  expect_true(file.exists(file))
})


test_that("extract_memory fails correctly when file does not exist", {
  expect_true(is.na(extract_memory("aaaa")))
})
