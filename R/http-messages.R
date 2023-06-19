#' Generic HTTP Response Messages
#'
#' These functions provide generic HTTP response messages
#' based on the HTTP response status codes.
#'
#' @param status HTTP status code.
#' @param message An HTTP response message or `NULL`.
#'   A generic response message is provided when it is `NULL`
#'   based on [`http_status_codes`].
#' @param body A list, additional values to be returned.
#' @param req The request object.
#' @param res The response object.
#' 
#' @return `http_error` returns an error with a custom condition attribute
#'   after checking if the status code is at least 400.
#' 
#' `http_success` returns a list but checks that the status code is <400.
#'
#' `http_response` returns a list checking only that the status code is valid.
#'
#' `http_handler` behaves like `http_response` but it also sets the status code
#' and the body of the response object.
#' 
#' @examples 
#' try(http_error())
#' try(http_error(400))
#' try(http_error(400, "Sorry"))
#' 
#' str(http_success())
#' str(http_success(201))
#' str(http_success(201, "Awesome"))
#'
#' str(http_response(201, "Awesome", list(name = "Jane", count = 6)))
#'
#' req <- new.env()
#' res <- new.env()
#' str(http_handler(req, res, 201, "Awesome", list(name = "Jane", count = 6)))
#' res$status
#' str(res$body)
#' 
#' 
#' @seealso [`http_status_codes`]
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
        i[["message"]], 
        ifelse(!is.null(message), " - ", ""), one_line(message))
    i[] <- lapply(i, un_box)
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
        i[["message"]], 
        ifelse(!is.null(message), " - ", ""), one_line(message))
    i[] <- lapply(i, un_box)
    if (!is.null(body))
        i$body <- body
    structure(
        i,
        class = c("http_response", "list"))
}

#' @rdname http-messages
#' @export 
http_handler <- function(req, res,
    status = 200L,
    message = NULL,
    body = NULL) {
    x <- http_response(status = status,
        message = message,
        body = body)
    af <- api_framework(req, res)
    if (af == "plumber" || is.na(af)) {
        res$status <- unclass(x$status)
        res$body <- x
    }
    if (!is.na(af) && af == "RestRserve") {
        res$set_status_code(unclass(x$status))
        res$set_body(x)
    }
    x
}
