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

# timemoir alignment

    Code
      result <- timemoir(Sys.sleep(1.9), Sys.sleep(), interval = 2)
    Output
      benchmarking Sys.sleep(1.9) : 
      benchmarking Sys.sleep()    : 

