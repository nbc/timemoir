
<!-- README.md is generated from README.Rmd. Please edit that file -->

# timemoir

<!-- badges: start -->

[![R-CMD-check](https://github.com/nbc/timemoir/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/nbc/timemoir/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

The goal of timemoir is to get memory usage of large functions doing
many things (like `duckdb` or `arrow` calculation). `utils::Rprof` and
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

my_fun <- function(sec) {
  Sys.sleep(sec)
}

timemoir(my_fun(1), my_fun(2), my_fun())
#> benchmarking function my_fun(1) : 
#> benchmarking function my_fun(2) : 
#> benchmarking function my_fun() :
#> # A tibble: 3 × 4
#>   fname     duration error                                max_mem
#>   <chr>        <dbl> <chr>                                  <dbl>
#> 1 my_fun(1)       NA "could not find function \"my_fun\""       0
#> 2 my_fun(2)       NA "could not find function \"my_fun\""       0
#> 3 my_fun()        NA "could not find function \"my_fun\""       0
```
