#' HTTP Response Status Codes
#' 
#' Data frame with possible status codes and default messages
#' based on [RFC 9110](https://httpwg.org/specs/rfc9110.html#overview.of.status.codes).
#' See also <https://developer.mozilla.org/en-US/docs/Web/HTTP/Status>.
#' 
#' @examples
#' str(http_status_codes)
#' 
#' http_status_codes[http_status_codes$category == "Successful",]
#' 
#' http_status_codes["500",]
#' 
#' @export
http_status_codes <- structure(
    list(category = c("Informational", "Informational", 
    "Informational", "Informational", "Successful", "Successful", "Successful", 
    "Successful", "Successful", "Successful", "Successful", "Successful", "Successful", 
    "Successful", "Redirection", "Redirection", "Redirection", "Redirection", 
    "Redirection", "Redirection", "Redirection", "Redirection", "Client Error", 
    "Client Error", "Client Error", "Client Error", "Client Error", 
    "Client Error", "Client Error", "Client Error", "Client Error", 
    "Client Error", "Client Error", "Client Error", "Client Error", 
    "Client Error", "Client Error", "Client Error", "Client Error", 
    "Client Error", "Client Error", "Client Error", "Client Error", 
    "Client Error", "Client Error", "Client Error", "Client Error", 
    "Client Error", "Client Error", "Client Error", "Client Error", 
    "Server Error", "Server Error", "Server Error", "Server Error", 
    "Server Error", "Server Error", "Server Error", "Server Error", 
    "Server Error", "Server Error", "Server Error"), status = c(100L, 
    101L, 102L, 103L, 200L, 201L, 202L, 203L, 204L, 205L, 206L, 207L, 
    208L, 226L, 300L, 301L, 302L, 303L, 304L, 305L, 307L, 308L, 400L, 
    401L, 402L, 403L, 404L, 405L, 406L, 407L, 408L, 409L, 410L, 411L, 
    412L, 413L, 414L, 415L, 416L, 417L, 418L, 421L, 422L, 423L, 424L, 
    425L, 426L, 428L, 429L, 431L, 451L, 500L, 501L, 502L, 503L, 504L, 
    505L, 506L, 507L, 508L, 510L, 511L), message = c("Continue", 
    "Switching Protocols", "Processing", "Early Hints", "OK", "Created", 
    "Accepted", "Non-Authoritative Information", "No Content", "Reset Content", 
    "Partial Content", "Multi-Status", "Already Reported", "IM Used", 
    "Multiple Choice", "Moved Permanently", "Found", "See Other", 
    "Not Modified", "Use Proxy", "Temporary Redirect", "Permanent Redirect", 
    "Bad Request", "Unauthorized", "Payment Required", "Forbidden", 
    "Not Found", "Method Not Allowed", "Not Acceptable", "Proxy Authentication Required", 
    "Request Timeout", "Conflict", "Gone", "Length Required", "Precondition Failed", 
    "Payload Too Large", "URI Too Long", "Unsupported Media Type", 
    "Range Not Satisfiable", "Expectation Failed", "I'm a teapot", 
    "Misdirected Request", "Unprocessable Entity", "Locked", "Failed Dependency", 
    "Too Early", "Upgrade Required", "Precondition Required", "Too Many Requests", 
    "Request Header Fields Too Large", "Unavailable For Legal Reasons", 
    "Internal Server Error", "Not Implemented", "Bad Gateway", "Service Unavailable", 
    "Gateway Timeout", "HTTP Version Not Supported", "Variant Also Negotiates", 
    "Insufficient Storage", "Loop Detected", "Not Extended", "Network Authentication Required"
    )), class = "data.frame", row.names = c(100L, 101L, 102L, 103L, 
    200L, 201L, 202L, 203L, 204L, 205L, 206L, 207L, 208L, 226L, 300L, 
    301L, 302L, 303L, 304L, 305L, 307L, 308L, 400L, 401L, 402L, 403L, 
    404L, 405L, 406L, 407L, 408L, 409L, 410L, 411L, 412L, 413L, 414L, 
    415L, 416L, 417L, 418L, 421L, 422L, 423L, 424L, 425L, 426L, 428L, 
    429L, 431L, 451L, 500L, 501L, 502L, 503L, 504L, 505L, 506L, 507L, 
    508L, 510L, 511L))
