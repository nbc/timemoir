
<!-- README.md is generated from README.Rmd. Please edit that file -->

# timemoir

<!-- badges: start -->
<!-- badges: end -->

The goal of timemoir is to get memory used by a function “from the
source” (`/proc/<pid>/status`).

## Installation

You can install the development version of timemoir like so:

``` r
library(devtools)
devtools::install_github("nbc/timemoir")
```

## Example

``` r
library(timemoir)

my_function <- function() {
  Sys.sleep(2)
}

launch_function(my_function())
#> $result
#> NULL
#> 
#> $duration
#> [1] 2.010169
#> 
#> $max_mem
#> [1] 71252
```
