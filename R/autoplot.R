# This code is heavily inspired by `bench::autoplot()` and `bench::plot()`

#' Autoplot method for timemoir results (grouped bar chart)
#'
#' @param object A result from timemoir()
#' @param unit_memory unit for memory display: "MB" or "GB" (default to "MB")
#' @param ... unused
#'
#' @details This function requires some optional dependencies. [ggplot2][ggplot2::ggplot2-package],
#' [tidyr][tidyr::tidyr-package], and [dplyr][dplyr::dplyr-package].
#'
#' @return A ggplot object with grouped bars (duration, memory, cpu)
#' @examples
#' test_function <- function(n) {
#'   x <- rnorm(n)
#'   mean(x)
#' }
#'
#' res <- timemoir(test_function(1.2e7), test_function(1.5e7), test_function(1e7))
#'
#' if (require(ggplot2) && require(tidyr) && require(dplyr)) {
#'   plot(res)
#' }
# Lazily registered in `.onLoad()`
autoplot.timemoir <- function(object, unit_memory = c("MB", "GB"), ...) {
  unit_memory <- match.arg(unit_memory)

  rlang::check_installed(c("ggplot2", "tidyr"), "for `autoplot()`.")

  df <- object
  df <- df[is.na(df$error), ] # exclure les erreurs

  # Conversion mémoire
  mem_divisor <- if (unit_memory == "GB") 1024^2 else 1024
  mem_label <- if (unit_memory == "GB") "Memory (GB)" else "Memory (MB)"

  df <- dplyr::mutate(
    object,
    cpu = cpu_user + cpu_sys,
    max_used_mem = (max_mem - start_mem) / mem_divisor
  )

  df <- dplyr::select(df, fname, duration, cpu, max_used_mem)

  df <- tidyr::pivot_longer(df,
    cols = c(duration, cpu, max_used_mem),
    names_to = "metric",
    values_to = "value"
  )

  df <- dplyr::mutate(df,
    metric = dplyr::case_match(
      metric,
      "duration" ~ "Duration (s)",
      "cpu" ~ "CPU Time (s)",
      "max_used_mem" ~ paste0("Max Used ", mem_label)
    )
  )

  ggplot2::ggplot(df, ggplot2::aes(x = fname, y = value, fill = fname)) +
    ggplot2::geom_col(position = "dodge") +
    ggplot2::facet_wrap(~metric, scales = "free_y") +
    ggplot2::theme_minimal(base_size = 14) +
    ggplot2::labs(x = NULL, y = NULL, fill = "Function") +
    ggplot2::theme(
      axis.text.x = ggplot2::element_text(angle = 30, hjust = 1),
      legend.position = "none"
    )
}

#' @rdname autoplot.timemoir
#' @param x A `timemoir` object.
#' @param y Ignored, required for compatibility with the `plot()` generic.
#' @export
plot.timemoir <- function(x, unit_memory = c("MB", "GB"), ..., y) {
  unit_memory <- match.arg(unit_memory)
  ggplot2::autoplot(x, unit_memory = unit_memory, ...)
}

# just to avoid R CMD check notes
utils::globalVariables(c("fname", "metric", "value", "start_mem", "max_mem", "max_used_mem", "cpu_user", "cpu_sys", "cpu", "duration"))
