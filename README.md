
<!-- README.md is generated from README.Rmd. Please edit that file -->

# timemoir

<!-- badges: start -->

[![R-CMD-check](https://github.com/nbc/timemoir/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/nbc/timemoir/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/nbc/timemoir/branch/main/graph/badge.svg)](https://app.codecov.io/gh/nbc/timemoir?branch=main)
<!-- badges: end -->

## Overview

This package offers a low level framework for benchmarking the memory
usage and execution time of R functions. It is designed to assist
developers and analysts in profiling and optimizing the performance of
their code, particularly for long-running functions or processes that
rely heavily on disk I/O or in memory database queries like `arrow` and
`duckdb` that can not be benchmark by classic methods.

Key Features:

- **Detailed Profiling**: Measures the memory usage and execution time
  of functions, providing insights into their performance.
- **Error Reporting**: Captures errors during execution to aid debugging
  and improve reliability.

To achieve its goal, `timemoir` fork an R process that executes the
function, while the main process read memory usage in
`/proc/<pid>/status`. Althoug a bit crude this approach is effective.

It’s a simple but effective approach.

> ❗ **Note**: This package works only on **Linux**.  
> It relies on the `/proc/<pid>/status` filesystem to track memory
> usage.

## Installation

To install the package, run the following command in your R console:

``` r
devtools::install_github("nbc/timemoir")
```

## Example

``` r
library(timemoir)

test_function <- function(n) {
  x <- rnorm(n); mean(x)
}

timemoir(
  test_function(1e3),
  test_function(1e6),
  test_function(1e8)
)
#> benchmarking test_function(1000)  : 
#> benchmarking test_function(1e+06) : 
#> benchmarking test_function(1e+08) : ..
#> # A tibble: 3 × 5
#>   fname                duration error start_mem max_mem
#>   <chr>                   <dbl> <chr>     <dbl>   <dbl>
#> 1 test_function(1000)  0.000362 <NA>     102512  100976
#> 2 test_function(1e+06) 0.0252   <NA>     102384  100976
#> 3 test_function(1e+08) 2.59     <NA>     102512  884080
```
