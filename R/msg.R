#' Write Logging Information to STDOUT or STDERR
#'
#' A simple logging utility that writes the log message to STDOUT or STDERR
#' in plain text, JSON, or comma separated format.
#'
#' @param title Character, the title of the logging message.
#' @param message Character, a more detailed logging message.
#' @param level Log level; one of `"ALL"`, `"TRACE"`, `"DEBUG"`, `"INFO"`, 
#'   `"SUCCESS"`, `"WARN"`, `"ERROR"`, `"FATAL"`, `"OFF"` (case insensitive).
#' @param format Log format: `"PLAIN"` (default), `"JSON"`, `"CSV"`
#'   (case insensitive).
#' @param digits Integer of length 1, digits for seconds (default `3L` meaning milliseconds).
#' @param x,y Strings to combine.
#'
#' @details
#' The `TRYR_ERR_LEVEL` environment variable determines where the log message is written.
#' If the log level is at least the one or above the `TRYR_ERR_LEVEL` value
#' (or `"WARN"` when it is unset or null) the message is written to STDERR,
#' otherwise it is written to STDOUT.
#'
#' The log message is only written when the log level is at least the one or higher than specified
#' by the `TRYR_LOG_LEVEL` environment variables; or `"INFO"` when the variable is unset or null.
#'
#' The log format can be plain text, JSON, or comma separated text.
#' When the log format is `NULL` the `TRYR_LOG_FORMAT` environment variables is checked.
#' If it is unset or null, the format is considered plain text.
#'
#' The logging message will be formed by combining the `title` and the `message` parts.
#' The log info also contains the process ID, a timestamp (using [Sys.time()]), and the log level.
#' The timestamp prints out fractional seconds according to `digits`. When `digits` is `NULL`
#' it checks the `TRYR_LOG_DIGITS` environment variables and uses that value.
#' The default is 3 when `TRYR_LOG_DIGITS` unset or null.
#'
#' Besides the usual log levels, there is an extra one `"SUCCESS"` that is
#' used to signal successful HTTP response codes (2xx).
#'
#' @return `msg` invisibly returns logical indicating if the log message was written 
#'   (`TRUE`) or not (`FALSE`). A side effect is a log message to STDOUT or STDERR.
#'
#' The `%+%` special pastes the right and left hand side together into s single string.
#'
#' @seealso [paste0()], [sprintf()]
#' @examples
#' n <- 5
#' "Sample " %+% "size " %+% "n = " %+% n %+% "."
#' 
#' msg("Success", "We did it!")
#' msg("Success", "We did it!", "SUCCESS")
#' msg("Error", "Oh no! n cannot be " %+% n, "ERROR")
#'
#' msg("Success", "We did it!", "SUCCESS", format = "JSON")
#' msg("Success", "We did it!", format = "JSON")
#' msg("Error", "Oh no ...", "ERROR", format = "JSON")
#'
#' msg("Success", "We did it!", digits = 0)
#' msg("Success", "We did it!", digits = 6)
#'
#' @name msg
NULL

#' @rdname msg
#' @export 
msg <- function(
    title = "",
    message = "",
    level = "INFO",
    format = NULL,
    digits = NULL
) {
    levels <- c(
        ALL = 0L, 
        TRACE = 1L, 
        DEBUG = 2L, 
        INFO = 3L, 
        SUCCESS = 4L, 
        WARN = 5L, 
        ERROR = 6L, 
        FATAL = 7L, 
        OFF = 8L)
    level <- toupper(level)
    if (!(level %in% names(levels)))
        stop("Log level is incorrectly set.")
    LOG_LEVEL <- toupper(Sys.getenv("TRYR_LOG_LEVEL", "INFO"))
    if (!(LOG_LEVEL %in% names(levels)))
        stop("The TRYR_LOG_LEVEL environment variable is incorrectly set.")
    ERR_LEVEL <- toupper(Sys.getenv("TRYR_ERR_LEVEL", "WARN"))
    if (!(ERR_LEVEL %in% names(levels)))
        stop("The TRYR_ERR_LEVEL environment variable is incorrectly set.")
    if (level == "OFF" || levels[LOG_LEVEL] > levels[level])
        return(invisible(FALSE))

    st <- Sys.time()
    # title <- one_line(title)
    # message <- one_line(message)
    if (is.null(format)) {
        format <- "PLAIN"
        ENV_FORMAT <- Sys.getenv("TRYR_LOG_FORMAT", "PLAIN")
        if (!is.null(ENV_FORMAT))
            format <- toupper(ENV_FORMAT)
    }
    format <- match.arg(toupper(format), c("PLAIN", "JSON", "CSV"))
    if (is.null(digits)) {
        digits <- 3L
        ENV_DIGITS <- Sys.getenv("TRYR_LOG_DIGITS")
        if (ENV_DIGITS != "")
            digits <- as.integer(ENV_DIGITS)
    }
    # op <- options(digits.secs = as.integer(digits))
    # on.exit(options(op))
    pid <- Sys.getenv("TRYR_PROC_NAME", as.character(Sys.getpid()))
    dt <- as.character(format(Sys.time(), digits = as.integer(digits)))
    if (format == "JSON") {
        msg <- paste0(
            "{\"pid\":\"",
            pid,
            "\",\"ts\":\"",
            dt,
            "\",\"ut\":",
            as.numeric(st),
            ",\"level\":\"",
            level,
            "\",\"value\":",
            levels[level],
            ",\"title\":\"",
            title,
            "\",\"message\":\"",
            message,
            "\"}\n")
    }
    if (format == "CSV") {
        msg <- paste0(
            "\"", pid, "\",\"",
            dt, "\",",
            as.numeric(st), ",",
            level, ",",
            levels[level], ",\"",
            title, "\",\"",
            message, "\"\n")
    }
    if (format == "PLAIN") {
        msg <- paste0(
            pid,
            " | ",
            dt,
            " [",
            switch(level,
                TRACE   = "TRACE  ", 
                DEBUG   = "DEBUG  ", 
                INFO    = "INFO   ", 
                SUCCESS = "SUCCESS",
                WARN    = "WARN   ", 
                ERROR   = "ERROR  ", 
                FATAL   = "FATAL  ", 
                OFF     = "OFF    "),
            "] ",
            title,
            if (message == "") "" else " - ",
            message,
            "\n")
    }
    if (levels[level] >= levels[ERR_LEVEL]) {
        cat(msg, file = stderr())
    } else {
        cat(msg, file = stdout())
    }
    invisible(TRUE)
}

#' @rdname msg
#' @export
"%+%" <- function(x, y) {
    paste0(as.character(c(x, y)), collapse = "")
}
