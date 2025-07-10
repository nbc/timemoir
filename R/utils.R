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
#' @importFrom ps ps_memory_info ps_handle
extract_memory <- function(pid) {
  tryCatch({
    vmrss_value <- as.integer(ps::ps_memory_info(ps::ps_handle(pid))[['rss']] / 1024)
  },
  error = function(e) {
    if (e$message == "No such file or directory") {
      stop("Process doesn't exist")
    } else {
      stop(e)
    }
  })
}

convert_memory <- function(memory_in_ko) {
  units <- c("Ko", "Mo", "Go", "To")
  unit_index <- 1

  size <- memory_in_ko
  while (size >= 1024 && unit_index < length(units)) {
    size <- size / 1024
    unit_index <- unit_index + 1
  }

  formatted_size <- sprintf("%.2f %s", size, units[unit_index])
  return(formatted_size)
}
