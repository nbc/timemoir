
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

As this package reads `/proc/<pid>/status`, it doesn’t work on windows.

## Installation

To install the package, run the following command in your R console:

``` r
devtools::install_github("nbc/timemoir")
```

## Example

``` r
library(timemoir)

timemoir(Sys.sleep(1), Sys.sleep(2), Sys.sleep())
#> benchmarking Sys.sleep(1) : .
#> benchmarking Sys.sleep(2) : ..
#> benchmarking Sys.sleep()  :
#> # A tibble: 3 × 5
#>   fname        duration error                                  start_mem max_mem
#>   <chr>           <dbl> <chr>                                      <dbl>   <dbl>
#> 1 Sys.sleep(1)     1.00  <NA>                                      83240   84648
#> 2 Sys.sleep(2)     2.01  <NA>                                      83308   83692
#> 3 Sys.sleep()     NA    "argument \"time\" is missing, with n…     83444   81652
```
