#' Try mechanism for Plumber APIs
#' 
#' Helps differentiate between client (4xx) and server (5xx) errors,
#' and provides a mechanism to return custom status codes
#' in combination with `http_error()` and `https_success()`.
#' 
#' @param res The response object.
#' @param expr An expression.
#' @param x The return value from `try(expr)`.
#' @param silent Should the report of error messages be suppressed by [try()]?
#' @param ... Arguments passed to [try()]
#' 
#' @return A list or the results from `expr`.
#'   A side effect is setting of the response status code and a log message.
#' 
#' @examples 
#' res <- list()
#' http_try(res)
#' http_try(res, {2 + 2})
#' http_try(res, http_error(401))
#' http_try(res, http_success(201))
#' http_try(res, {lm(NULL)})
#' http_try(res, {stop("Stop!!!")})
#' 
#' f <- function() stop("Stop!!!")
#' http_try(res, {f()})
#' http_try_handler(res, {try(f())})
#' 
#' @name http-try
NULL


#' @rdname http-try
#' @export 
http_try_handler <- function(res, x) {
    if (missing(res))
        res <- list()
    if (inherits(x, "try-error")) {
        if (!inherits(attr(x, "condition"), "http_error")) {
            msg(
                title = paste0(
                    "Status 500: ", 
                    http_status_codes["500", "message"]),
                message = geterrmessage(),
                level = "ERROR"
            )
            res$status <- 500L
            i <- as.list(
                http_status_codes["500",]
            )
            i[] <- lapply(i, jsonlite::unbox)
            i
        } else {
            msg(
                title = paste0(
                    "Status ", attr(x, "condition")$status, ": ", 
                    attr(x, "condition")$message),
                level = "ERROR"
            )
            res$status <- attr(x, "condition")$status
            i <- unclass(
                attr(x, "condition")
            )
            i[] <- lapply(i, jsonlite::unbox)
            i
        }
    } else {
        if (!inherits(x, "http_success")) {
            msg(
                title = paste0(
                    "Status 200: ", 
                    http_status_codes["200", "message"]),
                level = "SUCCESS"
            )
            x
        } else {
            msg(
                title = paste0(
                    "Status ", x$status, ": ", 
                    x$message),
                level = "SUCCESS"
            )
            res$status <- x$status
            unclass(
                x # no unboxing applied
            )
        }
    }
}

#' @rdname http-try
#' @export 
http_try <- function(res, expr, silent = TRUE, ...) {
    http_try_handler(
        res = res,
        x = try(
            expr,
            silent = silent,
            ...
        )
    )
}
