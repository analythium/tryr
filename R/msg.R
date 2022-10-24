#' Message to STDOUT or STDERR
#' 
#' @param title Title.
#' @param message Message.
#' @param level Log level.
#' @param json Log format in JSON (default `TRUE`).
#' @param digits Digits for seconds (default `2L`).
#' 
#' @return `TRUE` or `FALSE`: did a log event happened?
#'   A side effect is a log message to STDOUT or STDERR.
#' 
#' @examples
#' msg("Success", "We did it!")
#' msg("Success", "We did it!", "SUCCESS")
#' msg("Crap", "Oh no ...", "ERROR")
#' 
#' msg("Success", "We did it!", "SUCCESS", json=TRUE)
#' msg("Success", "We did it!", json=TRUE)
#' msg("Crap", "Oh no ...", "ERROR", json=TRUE)
#' 
#' msg("Success", "We did it!", digits = 0)
#' msg("Success", "We did it!", digits = 6)
#'  
#' @export 
msg <- function(
    title = "",
    message = "",
    level = "INFO",
    json = NULL,
    digits = NULL
) {
    st <- Sys.time()
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
    ENV_LEVEL <- toupper(Sys.getenv("TRYR_LOG_LEVEL", "INFO"))
    if (!(ENV_LEVEL %in% names(levels)))
        stop("The TRYR_LOG_LEVEL environment variable is incorrectly set.")
    ERR_LEVEL <- toupper(Sys.getenv("TRYR_ERR_LEVEL", "WARN"))
    if (!(ERR_LEVEL %in% names(levels)))
        stop("The TRYR_ERR_LEVEL environment variable is incorrectly set.")
    if (level == "NONE")
        return(invisible(FALSE))
    title <- oneline(title)
    message <- oneline(message)
    if (is.null(json)) {
        json <- FALSE
        ENV_FORMAT <- Sys.getenv("TRYR_LOG_FORMAT", "TXT")
        if (!is.null(ENV_FORMAT))
            json <- tolower(ENV_FORMAT) == "json"
    }
    if (is.null(digits)) {
        digits <- 2L
        ENV_DIGITS <- Sys.getenv("TRYR_LOG_DIGITS")
        if (ENV_DIGITS != "")
            digits <- as.integer(ENV_DIGITS)
    }
    op <- options(digits.secs = as.integer(digits))
    on.exit(options(op))

    dt <- as.character(st)
    if (json) {
        msg <- paste0(
            "{\"ts\":\"",
            dt,
            "\",\"ut\":",
            as.numeric(st),
            ",\"level\":\"",
            level,
            "\",\"value\":",
            as.integer(levels[tolower(level)]),
            ",\"title\":\"",
            title,
            "\",\"message\":\"",
            message,
            "\"}\n")
    } else {
        msg <- paste0(
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
    if (levels[ENV_LEVEL] <= levels[level]) {
        if (levels[level] >= levels[ERR_LEVEL]) {
            cat(msg, file = stderr())
        } else {
            cat(msg, file = stdout())
        }
        invisible(TRUE)
    } else {
        invisible(FALSE)
    }
}

#' Remove newlines and leading/trailing white space from a string
#' 
#' @param x A string, possibly a vector
#' 
#' @return An atomic character vector.
#' @noRd
oneline <- function(x) {
    trimws(gsub("[\r\n]", " ", paste(as.character(x), collapse = " ")))
}
