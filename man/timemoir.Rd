% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/timemoir.R
\name{timemoir}
\alias{timemoir}
\title{Benchmark functions}
\usage{
timemoir(..., verbose = TRUE, interval = 0.1)
}
\arguments{
\item{...}{functions to benchmark.}

\item{verbose}{A boolean. If TRUE (default) print information messages.}

\item{interval}{(default 0.1) sleep interval between memory check in sec}
}
\value{
A result tibble with one row per benchmarked function and 5 columns:
\itemize{
\item \code{fname}, function name (as string).
\item \code{duration} duration (in sec) of the function or NA if function fails.
\item \code{error}, error message if function fails, NA otherwise.
\item \code{start_mem} memory used before function benchmark (in KB).
\item \code{max_mem} max used memory (in KB).
}
}
\description{
launch functions in background and watch the pid file to get used memory.

This function is best used with long running functions like \code{arrow} or
\code{duckdb} requests that doesn't fit with classic benchmarking methods like
\code{utils::Rprof} and \code{profmem}.

memory is extracted every \code{interval} sec in \verb{/proc/<pid>/status}
\itemize{
\item \code{start_mem} is measured just before launching the function.
\item \code{max_mem} is the max of all measured mem
}
}
\examples{
timemoir(Sys.sleep(2), Sys.sleep())

timemoir(Sys.sleep(1), Sys.sleep(), verbose=FALSE)
}
