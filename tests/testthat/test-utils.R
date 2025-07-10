test_that("convert_memory works", {
  expect_snapshot(convert_memory(0))
  expect_snapshot(convert_memory(1024))
  expect_snapshot(convert_memory(1024 * 1024))
  expect_snapshot(convert_memory(1024 * 1024 * 1024))
})

test_that("extract_memory fails correctly when file does not exist", {
  expect_error(extract_memory(-1))
})
