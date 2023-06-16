## An example RestRserve API from https://restrserve.org/

library(RestRserve)

app = Application$new()
app$logger$set_log_level("off") # using tryr's logger


foo <- function(x) {
  x <- as.numeric(x)
  if (x < 0)
    stop("'x' is too low.")
  "Success!"
}

bar <- function(x) {
  x <- suppressWarnings(as.numeric(x))
  if (is.na(x))
    tryr::http_error(400L, "Unexpected input.")
  foo(x)
}

app$add_post(
    path = "/test", 
    FUN = function(req, res) {
        x <- req$parameters_query[["x"]]
        out <- foo(x = x)
        res$set_content_type("application/json")
        res$set_body(out)
})

app$add_post(
    path = "/try", 
    FUN = function(req, res) {
        out <- tryr::http_try(req, res, {
            x <- req$parameters_query[["x"]]
            if (is.null(x))
                stop("'x' is missing", call. = FALSE)
            bar(x = x)
        })
        res$set_content_type("application/json")
        res$set_body(out)
})

backend = BackendRserve$new()
backend$start(app, http_port = 8000)

# Rscript inst/examples/RestRserve.R
# curl -i -X POST "http://localhost:8000/try?x=0"
# curl -i -X POST "http://localhost:8000/try?x=-1"
# curl -i -X POST "http://localhost:8000/try?x=a"
# curl -i -X POST "http://localhost:8000/try?x="
