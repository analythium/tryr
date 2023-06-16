## An example Plumber API from https://www.rplumber.io/

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

#* @post /test
function(x) {
  foo(x = x)
}

#* @post /try
function(req, res, x) {
  tryr::http_try(req, res, {
    if (missing(x))
      stop("'x' is missing", call. = FALSE)
    bar(x = x)
  })
}

# R -e "plumber::plumb('inst/examples/plumber.R') |> plumber::pr_run(port=8000)"
# curl -i -X POST "http://localhost:8000/try?x=0"
# curl -i -X POST "http://localhost:8000/try?x=-1"
# curl -i -X POST "http://localhost:8000/try?x=a"
# curl -i -X POST "http://localhost:8000/try?x="
