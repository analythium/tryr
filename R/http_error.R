#' HTTP messages
#' 
#' @param status HTTP status code.
#' @param message Error message.
#' @param body A list, additional values to be returned.
#' @param req The request object.
#' @param res The response object.
#' @param ... Other arguments passed to `http_response`.
#' 
#' @return `http_error` returns an error with a custom condition attribute.
#'  `http_success` returns a list.
#' 
#' @examples 
#' try(http_error())
#' try(http_error(400))
#' try(http_error(400, "Sorry"))
#' 
#' http_success()
#' http_success(201)
#' http_success(201, "Awesome")
#' http_success(201, "Awesome", list(name = "Jane", count = 6))
#' 
#' 
#' @name http-messages
NULL

#' @rdname http-messages
#' @export 
http_error <- function(
    status = 500L,
    message = NULL
) {
    status <- as.integer(status)
    err <- http_status_codes[http_status_codes$status >= 400,]
    if (!(status %in% err$status))
        stop("Unrecognized status code.")
    i <- as.list(err[as.character(status),])
    i[["message"]] <- paste0(
        # "Status ", status, ": ", 
        i[["message"]], 
        ifelse(!is.null(message), " - ", ""), oneline(message))
    i[] <- lapply(i, jsonlite::unbox)
    stop(
        structure(
            i,
            class = c("http_error", "structured_error", "error", "condition")
        )
    )
}

#' @rdname http-messages
#' @export 
http_success <- function(
    status = 200L,
    message = NULL,
    body = NULL
) {
    status <- as.integer(status)
    succ <- http_status_codes[http_status_codes$status < 400,]
    if (!(status %in% succ$status))
        stop("Unrecognized status code.")
    i <- http_response(
        status = status,
        message = message,
        body = body)
    class(i) <- c("http_success", "http_response")
    i
}

#' @rdname http-messages
#' @export 
http_response <- function(
    status = 200L,
    message = NULL,
    body = NULL
) {
    status <- as.integer(status)
    if (!(status %in% http_status_codes$status))
        stop("Unrecognized status code.")
    i <- as.list(http_status_codes[as.character(status),])
    i[["message"]] <- paste0(
        # "Status ", status, ": ", 
        i[["message"]], 
        ifelse(!is.null(message), " - ", ""), oneline(message))
    i[] <- lapply(i, jsonlite::unbox)
    if (!is.null(body))
        i$body <- body
    structure(
        i,
        class = c("http_response", "list"))
}

#' @rdname http-messages
#' @export 
http_handler <- function(req, res, status, ...) {
    x <- http_response(status = status, ...)
    res$status <- x$status
    res$body <- x
    x
}
