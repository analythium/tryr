#' Message to STDOUT or STDERR
#' 
#' @param title Title.
#' @param message Message.
#' @param level Log level.
#' @param format Log format: `"PLAIN"` (default), `"JSON"`, `"CSV"`..
#' @param digits Digits for seconds (default `3L`).
#' 
#' @return `TRUE` or `FALSE`: did a log event happened?
#'   A side effect is a log message to STDOUT or STDERR.
#' 
#' @examples
#' msg("Success", "We did it!")
#' msg("Success", "We did it!", "SUCCESS")
#' msg("Crap", "Oh no ...", "ERROR")
#' 
#' msg("Success", "We did it!", "SUCCESS", format = "JSON")
#' msg("Success", "We did it!", format = "JSON")
#' msg("Crap", "Oh no ...", "ERROR", format = "JSON")
#' 
#' msg("Success", "We did it!", digits = 0)
#' msg("Success", "We did it!", digits = 6)
#'  
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
        OFF = 8L,
        NONE = 9L)
    level <- toupper(level)
    if (!(level %in% names(levels)))
        stop("Log level is incorrectly set.")
    LOG_LEVEL <- toupper(Sys.getenv("TRYR_LOG_LEVEL", "INFO"))
    if (!(LOG_LEVEL %in% names(levels)))
        stop("The TRYR_LOG_LEVEL environment variable is incorrectly set.")
    ERR_LEVEL <- toupper(Sys.getenv("TRYR_ERR_LEVEL", "WARN"))
    if (!(ERR_LEVEL %in% names(levels)))
        stop("The TRYR_ERR_LEVEL environment variable is incorrectly set.")
    if (level == "NONE")
        return(invisible(FALSE))
    if (level == "NONE" || levels[LOG_LEVEL] > levels[level])
        return(invisible(FALSE))

    st <- Sys.time()
    # title <- oneline(title)
    # message <- oneline(message)
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
    op <- options(digits.secs = as.integer(digits))
    on.exit(options(op))
    pid <- Sys.getenv("TRYR_PROC_NAME", as.character(Sys.getpid()))
    dt <- as.character(st)
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
                OFF     = "OFF    ",
                NONE    = "NONE   "),
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

#' Remove newlines and leading/trailing white space from a string
#' 
#' @param x A string, possibly a vector
#' 
#' @return An atomic character vector.
#' @export 
oneline <- function(x) {
    trimws(gsub("[\r\n]", " ", paste(as.character(x), collapse = " ")))
}
