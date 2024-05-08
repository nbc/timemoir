#' Benchmark functions
#'
#' @description
#' launch functions in background and watch the pid file to get max used memory
#'
#' @param ... functions to benchmark.
#' @param verbose A boolean. If TRUE (default) print information messages.
#'
#' @return a tibble with `fname`, the function name (as a string) passed to
#'   `timemoir`, max_mem` the max used memory, `duration` the duration of the
#'   function (or NA if function fails) and `error`, the error message if
#'   function fails (or NA if function pass)
#' @export
#'
#' @importFrom tibble tibble_row
#'
#' @examples
#' timemoir(Sys.sleep(2), Sys.sleep())
#'
#' timemoir(Sys.sleep(1), Sys.sleep(), verbose=FALSE)
timemoir <- function(...,
                     verbose = TRUE) {
  functions <- as.list(match.call(expand.dots = FALSE)$`...`)
  names(functions) <- sapply(functions, function(e) paste(deparse(e), collapse=" "))

  gc(FALSE)

  results <- list()

  for (fname in names(functions)) {
    flag_file <- tempfile()

    if (verbose) cat("benchmarking function", fname, ": ")
    my_fun <- functions[[fname]]

    child_proc <- parallel::mcparallel(wrapper(fname, my_fun, flag_file))
    max_mem <- watch_memory(child_proc$pid, flag_file, verbose)
    result <- parallel::mccollect(child_proc)[[1]]
    result$max_mem <- max_mem

    results[[length(results)+1]] <- result

    if (verbose) cat("\n")
    if (file.exists(flag_file)) file.remove(flag_file)
  }
  return(do.call("rbind", results))
}

wrapper <- function(fname, xfun, flag_file) {
  tryCatch({
    begin <- Sys.time()
    result <- eval(xfun)
    duration <- as.numeric(Sys.time() - begin, units="secs")

    return(tibble::tibble_row(fname = fname, duration = duration, error = NA_character_))
  }, error = function(e) {
    return(tibble::tibble_row(fname = fname, duration = NA_real_, error = e$message))
  }, finally = {
    file.create(flag_file)
  })
}

#' extract_memory
#'
#' @description
#' Extract VmRSS memory from pid file
#'
#' @param pid pid of processus
#'
#' @return memory in kB or NA
#' @noRd
#'
#' @examples
#'
#' pid <- Sys.getpid()
#' extract_memory(pid)
#'

extract_memory <- function(pid) {
  status_file_path <- sprintf("/proc/%s/status", pid)

  if (!file.exists(status_file_path)) return(NA_real_)

  lines <- readLines(status_file_path)
  vmrss_line <- grep("^VmRSS:", lines, value = TRUE)

  if (length(vmrss_line) > 0) {
    vmrss_value <- sub("VmRSS:\\s+([0-9]+) kB", "\\1", vmrss_line)
    return(as.numeric(vmrss_value))
  }
  return(NA_real_)
}

#' watch_memory
#'
#' @description
#'
#' watch memory until the file flag_file is created
#'
#' @param pid pid of processus
#' @param flag_file the flag file
#'
#' @return max memory in kB found
#' @noRd
watch_memory <- function(pid, flag_file, verbose) {
  max_mem <- 0
  min_mem <- Inf
  i = 0
  repeat {
    if (file.exists(flag_file)) {
      return(max_mem - min_mem)
    }
    mem <- extract_memory(pid)
    max_mem <- max(c(max_mem, mem), na.rm=T)
    min_mem <- min(c(min_mem, mem), na.rm=T)
    Sys.sleep(0.1)
    i = (i + 1) %% 10
    if (verbose & i == 0) cat(".")
  }
}
