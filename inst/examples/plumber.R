## An example Plumber API from https://www.rplumber.io/

foo <- function(x) {
  x <- as.numeric(x)
  if (x < 0)
    stop("'x' is too low.")
  "Success!"
}

bar <- function(x) {
  x <- as.numeric(x)
  if (is.na(x))
    tryr::http_error(400L, "Unexpected input.")
  foo(x)
}

#* @post /test
function(x) {
  foo(x = x)
}

#* @post /try
function(res, x) {
  tryr::http_try(res, {
    if (missing(x))
      tryr::http_error()
    bar(x = x)
  })
}
