#' Benchmark functions
#'
#' @description
#' Executes each function in a separate forked process and monitors its memory and cpu usage in real time
#'
#' This function is best used with long running functions like `arrow` or
#' `duckdb` requests that doesn't fit with classic benchmarking methods like
#' `utils::Rprof` and `profmem`.
#'
#' memory is extracted every `interval` sec with `ps::ps_memory_info`
#'
#' * `start_mem` is measured just before launching the function.
#' * `max_mem` is the max of all measured mem of the forked child
#'
#' cpu times and duration are given by `proc.time`
#'
#' @param ... functions to benchmark.
#' @param verbose A boolean. If TRUE (default) print information messages.
#' @param n An integer. number of time each function must run (default 1)
#' @param interval (default 0.1) sleep interval between memory check in sec
#' @return A result tibble with one row per benchmarked function and 7 columns:
#'
#' * `fname`, function name (as string).
#' * `duration` duration (in sec) of the function or NA if function fails.
#' * `error`, error message if function fails, NA otherwise.
#' * `start_mem` memory used before function benchmark (in KB).
#' * `max_mem` max used memory (in KB).
#' * `cpu_user` user cpu used in sec
#' * `cpu_sys` system cpu used in sec
#'
#' An error message such as "Process is a zombie" typically indicates that
#' the process was terminated after exceeding the allocated memory quota.
#'
#' @export
#'
#' @importFrom tibble tibble_row
#' @importFrom rlang enquos quo_text
#'
#' @examples
#'
#' test_function <- function(n) {
#'   x <- rnorm(n); mean(x)
#' }
#' timemoir(Sys.sleep(2), Sys.sleep(), test_function(1e7))
timemoir <- function(...,
                     verbose = TRUE,
                     n = 1,
                     interval = 0.1) {

  stopifnot(is.logical(verbose))
  stopifnot(is.numeric(interval))
  stopifnot(all.equal(n, as.integer(n)))

  functions <- rlang::enquos(...)
  names(functions) <- sapply(functions, function(q) rlang::quo_text(q))

  gc(FALSE)

  results <- list()

  max_str_length <- max(nchar(names(functions)))

  for (fname in names(functions)) {
    for (i in seq(n)) {
      flag_file <- tempfile()

      row <- tibble::tibble_row(fname = fname, duration = NA_real_, error = NA_character_, start_mem = NA_real_, max_mem = NA_real_, cpu_user = NA_real_, cpu_sys = NA_real_)

      text <- paste0("benchmarking ", fname, strrep(" ", max_str_length - nchar(fname)), sep = "")
      my_fun <- functions[[fname]]

      child <- parallel::mcparallel(wrapper(fname, my_fun, flag_file))

      res <- tryCatch({
        max_mem <- watch_memory(child$pid, flag_file, verbose, interval, text)
        out <- parallel::mccollect(child)[[1]]

        if (inherits(out, "try-error")) {
          row$error <- as.character(out)
        } else if (!is.null(out$error)) {
          row$error <- out$error
        } else {
          row$duration <- out$proc_time[['elapsed']]
          row$start_mem <- out$start_mem
          row$max_mem <- max_mem
          row$cpu_user <- out$proc_time[['user.self']]
          row$cpu_sys <- out$proc_time[['sys.self']]
        }
      }, error = function(e) {
        e
      }, finally = {
        if (file.exists(flag_file)) file.remove(flag_file)
      })

      if (inherits(res, "error")) {
        row$error <- res$message
      }

      results[[length(results)+1]] <- row

      if (verbose) cat("\n")
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
#' @importFrom rlang eval_tidy
#' @noRd
wrapper <- function(fname, xfun, flag_file) {
  tryCatch({
    start_mem <- extract_memory(Sys.getpid())
    begin <- proc.time()

    result <- rlang::eval_tidy(xfun)

    proc_time <- proc.time() - begin
    return(list(start_mem = start_mem, proc_time = proc_time))
  }, error = function(e) {
    return(list(error = e$message))
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
    if (file.exists(flag_file) | !ps::ps_is_running(ps::ps_handle(pid))) {
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
