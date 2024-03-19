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

  if (!file.exists(status_file_path)) return(NA)

  lines <- readLines(status_file_path)
  vmrss_line <- grep("^VmRSS:", lines, value = TRUE)

  if (length(vmrss_line) > 0) {
    vmrss_value <- sub("VmRSS:\\s+([0-9]+) kB", "\\1", vmrss_line)
    return(as.numeric(vmrss_value))
  }
  return(NA)
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
#' @return a named list with `result`, the result of the function, max_mem` the
#'   max used memory, `duration` the duration of the function and `error`, the
#'   error message if function fails.
#' @export
#'
#' @examples
#' my_fun <- function(sec) {
#'   Sys.sleep(sec)
#'   return(TRUE)
#' }
#'
#' timemoir(my_fun(1))
#'
#' my_fun <- function(sec) {
#'   Sys.sleep(sec)
#'   return(TRUE)
#' }
#'
#' timemoir(my_fun())
timemoir <- function(xfun, flag_file = tempfile()) {
  if (file.exists(flag_file)) file.remove(flag_file)

  wrapper <- function(xfun) {
    tryCatch({
      begin <- Sys.time()
      result <- xfun
      duration <- as.numeric(Sys.time() - begin)
      return(list(result = result, duration = duration, error = NA))
    }, error = function(e) {
      return(list(result = NA, duration = NA, error = e))
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
