#' Try mechanism for Plumber APIs
#' 
#' Helps differentiate between client (4xx) and server (5xx) errors,
#' and provides a mechanism to return custom status codes
#' in combination with `http_error()` and `https_success()`.
#' 
#' @param req The request object.
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
#' res <- req <- list()
#' 
#' http_try(req, res)
#' http_try(req, res, {2 + 2})
#' http_try(req, res, http_error(401))
#' http_try(req, res, http_success(201))
#' http_try(req, res, {lm(NULL)})
#' http_try(req, res, {stop("Stop!!!")})
#' 
#' f <- function() stop("Stop!!!")
#' http_try(req, res, {f()})
#' http_try_handler(req, res, {try(f())})
#' 
#' @name http-try
NULL

#' @rdname http-try
#' @export 
http_try <- function(req, res, expr, silent = TRUE, ...) {
    http_try_handler(
        req = req,
        res = res,
        x = try(
            expr,
            silent = silent,
            ...
        )
    )
}

#' @rdname http-try
#' @export 
http_try_handler <- function(req, res, x) {
    if (missing(req))
        req <- list()
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
