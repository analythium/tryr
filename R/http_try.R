#' Client/Server Error Handling
#' 
#' Differentiate between client (4xx) and server (5xx) errors.
#' Provides a mechanism to return custom status codes
#' in combination with [`http_error()`] and [`http_success()`].
#' 
#' @param req The request object.
#' @param res The response object.
#' @param expr An R expression to try.
#' @param x The return value from `try(expr)`.
#' @param silent Logical, should the report of error messages be suppressed by [try()]?
#' @param ... Arguments passed to [try()]
#'
#' @details
#' If we catch an error:
#'
#' * the error is a clear server error coming from `stop()`
#'   * log it as an ERROR + print the error message to STDERR
#'   * return a generic status 500 message
#'   * set the status code of the response object to 500
#' * the error is a structured HTTP error coming from `http_error()`
#'   * log it as an ERROR with the message from the condition attribute
#'   * return the specific HTTP error code with the structured output
#'   * set the status code of the response object
#'
#' If we don't catch an error:
#'
#' * the object is of class `http_success()` (this comes in handy for async jobs and redirects)
#'   * log it as a SUCCESS with the message element
#'   * return the specific HTTP status code with the structured output
#'   * set the status code of the response object
#' * the object is NOT of class `http_success()`
#'   * log it as a SUCCESS with a generic 200 message
#'   * return the object as is (default status code 200 assumed)
#'
#' @return A list or the results from `expr`.
#'   A side effect is setting of the response status code on the response
#'   object and a log message to STDOUT or STDERR.
#' 
#' @examples 
#' req <- new.env()
#' res <- new.env()
#' 
#' http_try(req, res)
#' res$status
#'
#' http_try(req, res, { 2 + 2 })
#' res$status
#'
#' http_try(req, res, http_error(401))
#' res$status
#'
#' http_try(req, res, http_success(201))
#' res$status
#'
#' http_try(req, res, { lm(NULL) })
#' res$status
#'
#' http_try(req, res, { stop("Stop!!!") })
#' res$status
#'
#' 
#' f <- function() stop("Stop!!!")
#' http_try(req, res, { f() })
#' res$status
#'
#' http_try_handler(req, res, { try(f()) })
#' res$status
#'
#' @seealso [try()], [msg()]
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
    af <- api_framework(req, res)
    if (inherits(x, "try-error")) {
        if (!inherits(attr(x, "condition"), "http_error")) {
            msg(
                title = paste0(
                    "Status 500: ", 
                    http_status_codes["500", "message"]),
                message = one_line(geterrmessage()),
                level = "ERROR"
            )

            # res$status <- 500L
            if (af == "plumber" || is.na(af)) {
                res$status <- 500L
            }
            if (!is.na(af) && af == "RestRserve") {
                res$set_status_code(500L)
            }

            i <- as.list(
                http_status_codes["500",]
            )
            i[] <- lapply(i, un_box)
            i
        } else {
            msg(
                title = paste0(
                    "Status ", attr(x, "condition")$status, ": ", 
                    attr(x, "condition")$message),
                level = "ERROR"
            )

            # res$status <- attr(x, "condition")$status
            if (af == "plumber" || is.na(af)) {
                res$status <- attr(x, "condition")$status
            }
            if (!is.na(af) && af == "RestRserve") {
                res$set_status_code(attr(x, "condition")$status)
            }

            i <- unclass(
                attr(x, "condition")
            )
            i[] <- lapply(i, un_box)
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


            # res$status <- x$status
            if (af == "plumber" || is.na(af)) {
                res$status <- x$status
            }
            if (!is.na(af) && af == "RestRserve") {
                res$set_status_code(x$status)
            }

            unclass(
                x # no unboxing applied
            )
        }
    }
}
