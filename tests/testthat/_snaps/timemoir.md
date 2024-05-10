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
      result <- timemoir(Sys.sleep(1.5), Sys.sleep())
    Output
      benchmarking Sys.sleep(1.5) : .
      benchmarking Sys.sleep()    : 

