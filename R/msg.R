#' Message to STDIO or STDERR
#' 
#' @param title Title.
#' @param message Message.
#' @param level Log level.
#' @param json Log format in JSON (default `TRUE`).
#' @param digits Digits for seconds (default `2L`).
#' 
#' @return `TRUE` or `FALSE`: did a log event happened?
#'   A side effect is a log message to STDIO or STDERR.
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
    if (is.null(json)) {
        json <- FALSE
        OPT_FORMAT <- getOption("tryr.log.format")
        if (!is.null(OPT_FORMAT))
            json <- tolower(OPT_FORMAT) == "json"
        ENV_FORMAT <- Sys.getenv("TRYR_LOG_FORMAT", "TXT")
        if (!is.null(ENV_FORMAT))
            json <- tolower(ENV_FORMAT) == "json"
    }
    if (is.null(digits)) {
        digits <- 2L
        OPT_DIGITS <- getOption("tryr.log.digits")
        if (!is.null(OPT_DIGITS))
            digits <- as.integer(OPT_DIGITS)
        ENV_DIGITS <- Sys.getenv("TRYR_LOG_DIGITS")
        if (ENV_DIGITS != "")
            digits <- as.integer(ENV_DIGITS)
    }
    op <- options(digits.secs = as.integer(digits))
    on.exit(options(op))
    ENV_LEVEL <- Sys.getenv("TRYR_LOG_LEVEL", "INFO")
    levels <- list(
        all = 0L, 
        trace = 1L, 
        debug = 2L, 
        info = 3L, 
        success = 4L, 
        warn = 5L, 
        error = 6L, 
        fatal = 7L, 
        off = 8L)
    if (is.null(levels[tolower(ENV_LEVEL)])) {
        stop("The TRYR_LOG_LEVEL environment variable is incorrectly set.")
    }
    dt <- as.character(Sys.time())
    if (json) {
        msg <- paste0(
            "{\"ts\":\"",
            dt,
            "\",\"ut\":",
            as.integer(Sys.time()),
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
                OFF     = "OFF    "),
            "] ",
            title,
            if (message == "") "" else " - ",
            message,
            "\n")
    }
    if (as.integer(levels[tolower(ENV_LEVEL)]) <= as.integer(levels[tolower(level)])) {
        if (as.integer(levels[tolower(level)]) > 3L) {
            cat(msg, file = stderr())
        } else {
            cat(msg, file = stdout())
        }
        invisible(TRUE)
    } else {
        invisible(FALSE)
    }
}
