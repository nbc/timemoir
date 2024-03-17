flag_file <- "flag_file.txt"

extractVmRSS <- function(pid) {
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

watch_memory <- function(pid) {
  max_mem <- -Inf
  repeat {
    if (file.exists(flag_file)) {
      return(max_mem)
    }
    mem <- extractVmRSS(pid)
    max_mem <- max(c(max_mem, mem), na.rm=T)
    Sys.sleep(0.2)
  }
}

#' launch_function
#'
#' @param xfun
#'
#' @return
#' @export
#'
#' @examples
#' my_fun <- function(sec) {
#' Sys.sleep(sec)
#' return(TRUE)
#' }
#'
#' launch_function(my_fun(1))
launch_function <- function(xfun) {
  if (file.exists(flag_file)) file.remove(flag_file)

  wrapper <- function(xfun) {
    tryCatch({
      begin <- Sys.time()
      result <- xfun
      duration <- Sys.time() - begin
      return(list(result = result, duration = duration))
    }, error = function(e) {
      return(list(error = e))
    }, finally = {
      file.create(flag_file)
    })
  }
  child_proc <- parallel::mcparallel(wrapper(xfun))
  max_mem <- watch_memory(child_proc$pid)
  result <- parallel::mccollect(child_proc)[[1]]
  result$max_mem <- max_mem

  if (file.exists(flag_file)) file.remove(flag_file)

  return(result)
}

