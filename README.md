
<!-- README.md is generated from README.Rmd. Please edit that file -->

# timemoir

<!-- badges: start -->

[![R-CMD-check](https://github.com/nbc/timemoir/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/nbc/timemoir/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

The goal of `timemoir` is to get memory usage of large functions doing
many things (like `duckdb` or `arrow` calculations). `utils::Rprof` and
`profmem` don’t work well for this use case.

To achieve this goal, the `timemoir` fork an R processus that execute
the function while the main processus read memory usage in
`/proc/<pid>/status`.

This is a bit crude but works well for me.

As this package reads `/proc/<pid>/status`, it doesn’t work on windows.

## Installation

You can install the development version of timemoir like so:

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
#>   fname        duration error                                  max_mem start_mem
#>   <chr>           <dbl> <chr>                                    <dbl>     <dbl>
#> 1 Sys.sleep(1)     1.01  <NA>                                    84504     83224
#> 2 Sys.sleep(2)     2.01  <NA>                                    83548     83292
#> 3 Sys.sleep()     NA    "argument \"time\" is missing, with n…   81388     83436
```
