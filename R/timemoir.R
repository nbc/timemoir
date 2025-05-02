#' Benchmark functions
#'
#' @description
#' launch functions in background and watch the pid file to get used memory.
#'
#' This function is best used with long running functions like `arrow` or
#' `duckdb` requests that doesn't fit with classic benchmarking methods like
#' `utils::Rprof` and `profmem`.
#'
#' memory is extracted every `interval` sec in `/proc/<pid>/status`
#'
#' * `start_mem` is measured just before launching the function.
#' * `max_mem` is the max of all measured mem
#'
#' @param ... functions to benchmark.
#' @param verbose A boolean. If TRUE (default) print information messages.
#' @param n An integer. number of time each function must run (default 1)
#' @param interval (default 0.1) sleep interval between memory check in sec
#' @return A result tibble with one row per benchmarked function and 5 columns:
#'
#' * `fname`, function name (as string).
#' * `duration` duration (in sec) of the function or NA if function fails.
#' * `error`, error message if function fails, NA otherwise.
#' * `start_mem` memory used before function benchmark (in KB).
#' * `max_mem` max used memory (in KB).
#'
#' @export
#'
#' @importFrom tibble tibble_row
#'
#' @examples
#' timemoir(Sys.sleep(2), Sys.sleep())
#'
#' timemoir(Sys.sleep(1), Sys.sleep(), verbose=FALSE)
timemoir <- function(...,
                     verbose = TRUE,
                     n = 1,
                     interval = 0.1) {

  stopifnot(is.logical(verbose))
  stopifnot(is.numeric(interval))
  stopifnot(all.equal(n, as.integer(n)))

  functions <- as.list(match.call(expand.dots = FALSE)$`...`)
  names(functions) <- sapply(functions, function(e) paste(deparse(e), collapse=" "))

  gc(FALSE)

  results <- list()

  max_str_length <- max(nchar(names(functions)))

  for (fname in names(functions)) {
    for (i in seq(n)) {
      flag_file <- tempfile()

      text <- paste0("benchmarking ", fname, strrep(" ", max_str_length - nchar(fname)), sep = "")
      my_fun <- functions[[fname]]

      child_proc <- parallel::mcparallel(wrapper(fname, my_fun, flag_file))
      max_mem <- watch_memory(child_proc$pid, flag_file, verbose, interval, text)
      result <- parallel::mccollect(child_proc)[[1]]

      result$max_mem <- max_mem

      results[[length(results)+1]] <- result

      if (verbose) cat("\n")
      if (file.exists(flag_file)) file.remove(flag_file)
    }
  }
  return(do.call("rbind", results))
}

#' a wrapper that calculate time and
#'
#' @param fname function name
#' @param xfun function to launch
#' @param flag_file flag file to create
#'
#' @return a tibble row with all information needed
#' @noRd
wrapper <- function(fname, xfun, flag_file) {
  start_mem <- extract_memory(Sys.getpid())
  tryCatch({
    begin <- Sys.time()
    result <- eval(xfun)
    duration <- as.numeric(Sys.time() - begin, units="secs")

    return(data = tibble::tibble_row(fname = fname, duration = duration, error = NA_character_, start_mem = start_mem))
  }, error = function(e) {
    return(tibble::tibble_row(fname = fname, duration = NA_real_, error = e$message, start_mem = start_mem))
  }, finally = {
    file.create(flag_file)
  })
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
#' @importFrom cli cli_progress_bar cli_progress_update cli_progress_done
watch_memory <- function(pid, flag_file, verbose = TRUE, interval = 1, text = "Surveillance") {
  max_mem <- 0
  start_time <- Sys.time()
  elapsed <- round(difftime(Sys.time(), start_time, units = "secs"))

  use_cli <- verbose && interactive()
  pb <- NULL

  if (use_cli) {
    pb <- cli::cli_progress_bar(
      format = "{text} : Elapsed time: {elapsed}s / Max memory usage : {convert_memory(max_mem)}",
      clear = FALSE
    )
  }

  repeat {
    if (file.exists(flag_file)) {
      if (use_cli) cli::cli_progress_done()
      return(max_mem)
    }

    mem <- extract_memory(pid)
    max_mem <- max(c(max_mem, mem), na.rm = TRUE)
    Sys.sleep(interval)

    if (use_cli) {
      elapsed <- round(as.numeric(difftime(Sys.time(), start_time, units = "secs")))
      cli::cli_progress_update()
    }
  }
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

convert_memory <- function(size_kb) {
  units <- c("Ko", "Mo", "Go", "To")
  unit_index <- 1

  size <- size_kb
  while (size >= 1024 && unit_index < length(units)) {
    size <- size / 1024
    unit_index <- unit_index + 1
  }

  formatted_size <- sprintf("%.2f %s", size, units[unit_index])
  return(formatted_size)
}
