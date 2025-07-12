
<!-- README.md is generated from README.Rmd. Please edit that file -->

# timemoir

<!-- badges: start -->

[![R-CMD-check](https://github.com/nbc/timemoir/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/nbc/timemoir/actions/workflows/R-CMD-check.yaml)
[![Codecov test
coverage](https://codecov.io/gh/nbc/timemoir/branch/main/graph/badge.svg)](https://app.codecov.io/gh/nbc/timemoir?branch=main)
<!-- badges: end -->

## Overview

The goal of timemoir is to benchmark the memory usage, CPU usage, and
execution time of functions that cannot be accurately profiled using
traditional benchmarking tools. It is particularly useful for profiling
**long-running or memory-intensive operations**, such as those involving
in-memory analytics with `arrow` or `duckdb`.

Unlike traditional profilers like `Rprof()` or `profmem`, `timemoir`
uses a **forked R process** to run each function in isolation, while the
parent process monitors memory consumption via
[`ps::ps_memory_info()`](https://ps.r-lib.org/) and `proc.time()`.

It’s a simple but effective approach.

## Features:

- Memory Profiling: Tracks initial and peak memory usage (`start_mem`,
  `max_mem`)
- CPU Usage: Measures user and system CPU time
- Elapsed Time: Captures real execution time (`proc.time`)
- Error Handling: Catches and reports errors without stopping the
  benchmarking loop
- Repetition: Supports repeated benchmarking with `n` runs per function

> ❗ **Note**: This package works only on **Unix**. It relies on
> parallel package to fork a process.

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
  test_function(),
  test_function(1e3),
  test_function(1e6),
  test_function(1e8)
)
#> # A tibble: 4 × 7
#>   fname                duration error         start_mem max_mem cpu_user cpu_sys
#>   <chr>                   <dbl> <chr>             <dbl>   <dbl>    <dbl>   <dbl>
#> 1 test_function()      NA       "l'argument …        NA      NA   NA      NA    
#> 2 test_function(1000)   0.00100  <NA>            105264  104496    0.001   0    
#> 3 test_function(1e+06)  0.0270   <NA>            105264  104496    0.025   0.001
#> 4 test_function(1e+08)  2.69     <NA>            105264  887088    2.40    0.29
```

## Why use `timemoir`?

Benchmarking tools like `bench::mark()` or `microbenchmark()` are
powerful for **fast** functions. But if you’re dealing with:

- Queries that stream data from disk,
- `duckdb::dbGetQuery()` on large tables,
- `arrow::open_dataset()` and lazy evaluations,
- or R functions with unpredictable memory usage,

…then `timemoir` gives you visibility into what’s really happening — in
memory, CPU and in time.
