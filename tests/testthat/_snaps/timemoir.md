# timemoir works

    Code
      result$error[[1]]
    Output
      [1] NA

---

    Code
      result$error[[2]]
    Output
      [1] "argument \"time\" is missing, with no default"

# timemoir verbosity

    Code
      result <- timemoir(Sys.sleep(1.1), Sys.sleep())
    Output
      benchmarking function Sys.sleep(1.1) : .
      benchmarking function Sys.sleep() : 

