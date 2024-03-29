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
watch_memory <- function(pid, flag_file) {
  max_mem <- 0
  repeat {
    if (file.exists(flag_file)) {
      return(max_mem)
    }
    mem <- extract_memory(pid)
    max_mem <- max(c(max_mem, mem), na.rm=T)
    Sys.sleep(0.2)
  }
}

#' timemoir
#'
#' @description
#' launch xfun in background and watch the pid file to get max memory
#'
#' @param xfun the function to test
#' @param flag_file the flag file to use to check xfun has finished
#'
#' @return a tibble with `fname`, the function name (as a string) passed to
#'   `timemoir`, max_mem` the max used memory, `duration` the duration of the
#'   function (or NA if function fails) and `error`, the error message if
#'   function fails (or NA if function pass)
#' @export
#'
#' @importFrom tibble tibble_row
#' @importFrom rlang quo_name enquo
#'
#' @examples
#' my_fun <- function(sec) {
#'   Sys.sleep(sec)
#'   return(TRUE)
#' }
#'
#' rbind(timemoir(my_fun(1)), timemoir(my_fun()))
timemoir <- function(xfun, flag_file = tempfile()) {
  # extract name
  fname <- rlang::quo_name(rlang::enquo(xfun))

  if (file.exists(flag_file)) file.remove(flag_file)

  wrapper <- function(xfun) {
    tryCatch({
      begin <- Sys.time()
      result <- xfun
      duration <- as.numeric(Sys.time() - begin)

      return(tibble::tibble_row(fname = fname, duration = duration, error = NA_character_))
    }, error = function(e) {
      return(tibble::tibble_row(fname = fname, duration = NA_real_, error = e$message))
    }, finally = {
      file.create(flag_file)
    })
  }

  child_proc <- parallel::mcparallel(wrapper(xfun))
  max_mem <- watch_memory(child_proc$pid, flag_file)
  result <- parallel::mccollect(child_proc)[[1]]
  result$max_mem <- max_mem

  if (file.exists(flag_file)) file.remove(flag_file)

  return(result)
}
