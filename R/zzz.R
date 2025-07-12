.onLoad <- function(libname, pkgname) {
  if (.Platform$OS.type != "unix") {
    stop(
      "The 'timemoir' package only works on Unix systems where parallel works.\n",
      "Current platform: ", Sys.info()[["sysname"]]
    )
  }
}
