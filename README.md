
<!-- README.md is generated from README.Rmd. Please edit that file -->

# timemoir

<!-- badges: start -->
<!-- badges: end -->

The goal of timemoir is to get memory usage of large functions doing
many things (like `duckdb` or `arrow` calculation). `utils::Rprof` and
`profmem` don’t work well for this use case.

To achieve this goal, the `launch_function` fork an R processus that
execute the function while the main processus read memory usage in
`/proc/<pid>/status`.

This is a bit crude but works.

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

launch_function(my_function())
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
#> [1] 69884

launch_function(my_function(1))
#> $result
#> NULL
#> 
#> $duration
#> [1] 1.001282
#> 
#> $error
#> NULL
#> 
#> $max_mem
#> [1] 70204
```
