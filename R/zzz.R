.onLoad <- function(libname, pkgname) {
  if (.Platform$OS.type != "unix" || !dir.exists("/proc")) {
    stop(
      "The 'timemoir' package only works on Linux systems with the /proc filesystem.\n",
      "Current platform: ", Sys.info()[["sysname"]]
    )
  }
}
