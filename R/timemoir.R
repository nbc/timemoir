#' Benchmark functions
#'
#' @description
#' launch functions in background and watch the pid file to get used memory
#'
#' @param ... functions to benchmark.
#' @param verbose A boolean. If TRUE (default) print information messages.
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
                     interval = 0.1) {

  stopifnot(is.logical(verbose))
  stopifnot(is.numeric(interval))

  functions <- as.list(match.call(expand.dots = FALSE)$`...`)
  names(functions) <- sapply(functions, function(e) paste(deparse(e), collapse=" "))

  gc(FALSE)

  results <- list()

  max_str_length <- max(nchar(names(functions)))

  for (fname in names(functions)) {
    flag_file <- tempfile()

    if (verbose) cat("benchmarking ", fname, strrep(" ", max_str_length - nchar(fname)), " : ", sep = "")
    my_fun <- functions[[fname]]

    child_proc <- parallel::mcparallel(wrapper(fname, my_fun, flag_file))
    max_mem <- watch_memory(child_proc$pid, flag_file, verbose, interval)
    result <- parallel::mccollect(child_proc)[[1]]

    result$max_mem <- max_mem

    results[[length(results)+1]] <- result

    if (verbose) cat("\n")
    if (file.exists(flag_file)) file.remove(flag_file)
  }
  return(do.call("rbind", results))
}

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
watch_memory <- function(pid, flag_file, verbose, interval) {
  max_mem <- 0
  i = 0
  repeat {
    if (file.exists(flag_file)) {
      return(max_mem)
    }
    mem <- extract_memory(pid)
    max_mem <- max(c(max_mem, mem), na.rm=T)
    Sys.sleep(interval)
    i = (i + 1) %% 10
    if (verbose & i == 0) cat(".")
  }
}
