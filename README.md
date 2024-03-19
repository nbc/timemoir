
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
library(devtools)
devtools::install_github("nbc/timemoir")
```

## Example

``` r
library(timemoir)

my_function <- function(sec) {
  Sys.sleep(sec)
}

timemoir(my_function(1))
#> $result
#> NULL
#> 
#> $duration
#> [1] 1.001406
#> 
#> $error
#> NULL
#> 
#> $max_mem
#> [1] 70840

timemoir(my_function())
#> $result
#> NULL
#> 
#> $duration
#> NULL
#> 
#> $error
#> <simpleError in my_function(): argument "sec" is missing, with no default>
#> 
#> $max_mem
#> [1] 69664
```
