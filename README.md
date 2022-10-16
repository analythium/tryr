# tryr: Client/Server Error Handling for Plumber APIs

In client/server setups, the client might send user input that is
incorrect. In such cases the front end application needs to know that
the 4xx error status indicates that the message needs to be relayed to
the user to correct the input.

As opposed to this, when the server fails due to unexpected reasons, the
client only needs to know that an error with 5xx status happened. Logs
are essential for backend developers to diagnose the problem.

## Problem statement

The Plumber R package implements a simple error catching hook that
converts all responses that are an error condition to a status code
500 - Internal Server Error.

Let’s see this for an example API:

``` r
plumber::pr("inst/examples/plumber.R") |>
  plumber::pr_run(port=8000)
```

### Default behavior

We use a very simple handler calling the function `foo()`:

``` r
foo <- function(x) {
  x <- as.numeric(x)
  if (x < 0)
    stop("'x' is too low.")
  "Success!"
}

#* @post /test
function(x) {
  foo(x = x)
}
```

Here are the responses from this `/test` endpoint:

``` bash
curl --data "x=0" "http://localhost:8000/test"
# --- Response body ---
# ["Success!"]

curl --data "x=-1" "http://localhost:8000/test"
# --- Response body ---
# {"error":"500 - Internal server error",
# "message":"Error in foo(x = x): 'x' is too low.\n"}
# --- STDOUT ---
# <simpleError in foo(x = x): 'x' is too low.>
# --- STDERR ---
# Warning in foo(x = x) : NAs introduced by coercion

curl --data "x=a" "http://localhost:8000/test"
# --- Response body ---
# {"error":"500 - Internal server error",
# "message":"Error in if (x < 0) stop(\"'x' is too low.\"): missing value where TRUE/FALSE needed\n"}
# --- STDOUT ---
# <simpleError in if (x < 0) stop("'x' is too low."): missing value where TRUE/FALSE needed>

curl --data "" "http://localhost:8000/test"
# --- Response body ---
# {"error":"500 - Internal server error",
# "message":"Error in foo(x = x): argument \"x\" is missing, with no default\n"}
# --- STDOUT ---
# <simpleError in foo(x = x): argument "x" is missing, with no default>
```

As you can see, the response has a generic 500 HTTP status irrespective
of nature of the error. Moreover the response contains the error message
from R. On the back end, the error is printed to STDOUT, whereas a
warning got printed to STDERR.

This default behavior is undesired for multiple reasons:

- We need to be able to differentiate 4xx and 5xx errors
- When the error is 5xx, the error message itself might contain
  sensitive information that we should not leak to the client
- The detailed error message is helpful on the backend, but we should
  print it to STDERR instead of STDOUT

## Try/catch behavior

Alternatively, we can use some functions from tryr to handle these
inconveniences:

``` r
bar <- function(x) {
  x <- as.numeric(x)
  if (is.na(x))
    tryr::http_error(400L, "Unexpected input.")
  foo(x)
}

#* @post /try
function(res, x) {
  tryr::http_try(res, {
    if (missing(x))
      tryr::http_error()
    bar(x = x)
  })
}
```

Here are the outputs from the `/try` endpoint:

``` bash
curl --data "x=0" "http://localhost:8000/try"
# --- Response body ---
# ["Success!"]
# --- STDERR ---
# 2022-10-15 23:45:22.65 [SUCCESS] Status 200: OK

curl --data "x=-1" "http://localhost:8000/try"
# --- Response body ---
# {"category":"Server Error",
# "status":500,
# "message":"Internal Server Error"}
# --- STDERR ---
# 2022-10-15 23:45:26.88 [ERROR  ] Status 500: Internal Server Error
# Error in foo(x) : 'x' is too low.

curl --data "x=a" "http://localhost:8000/try"
# --- Response body ---
# "category":"Client Error",
# "status":400,
# "message":"Status 400: Bad Request - Unexpected input."}
# --- STDERR ---
# Warning in bar(x = x) : NAs introduced by coercion
# 2022-10-15 23:45:32.10 [ERROR  ] Status 400: Status 400: Bad Request - Unexpected input.

curl --data "" "http://localhost:8000/try"
# --- Response body ---
# {"category":"Server Error",
# "status":500,
# "message":"Status 500: Internal Server Error"}
# --- STDERR ---
# 2022-10-15 23:45:36.61 [ERROR  ] Status 500: Status 500: Internal Server Error
```

Now we can see that:

- Successful response (200) leaves a trace in STDERR along with the
  error messages
- We can differentiate 4xx and 5xx errors
- When the error is 5xx, the error message is not included
- The detailed error message is printed to STDERR

So how did we do it? Here is what you get in tryr: we used `http_try()`.
It is a wrapper that can handle *expected* and *unexpected* errors.
Expected errors give the desired HTTP statuses using `http_error()`.
Unexpected error are returned by `stop()` and we have very little
control over those (i.e. were written by someone else).

## Implementation

The logic inside `http_try()` is this:

*If we catch an error:*

- the error is a clear server error coming from `stop()`
  - log it as an ERROR + print the error message to STDERR
  - return a generic status 500 message
  - set the status code of the response object to 500
- the error is a structured HTTP error coming from `http_error()`
  - log it as an ERROR with the message from the condition attribute
  - return the specific HTTP error code with the structured output
  - set the status code of the response object

*If we don’t catch an error:*

- the object is of class `http_success()`
  - log it as a SUCCESS with the message element
  - return the specific HTTP status code with the structured output
  - set the status code of the response object
- the object is NOT of class `http_success()`
  - log it as a SUCCESS with a generic 200 message
  - return the object as is (default status code 200 assumed)

Messages are handled by the `msg` function. Here is how you can add a
preroute hook. Here we add a logger to print incoming request info (HTTP
method and route) to STDOUT. For the sake of better ingest the logs we
can set the logging type to JSON and the timestamp precision to 6
digits.

``` r
Sys.setenv(
  TRYR_LOG_FORMAT = "JSON",
  TRYR_LOG_DIGITS = "6"
)
plumber::pr("inst/examples/plumber.R") |>
  plumber::pr_hooks(
    list(
      preroute = function(data, req, res) {
        tryr::msg(
          title = paste(
            method = req$REQUEST_METHOD, 
            path = req$PATH_INFO
          ),
          level = "INFO"
        )
      }
    )
  ) |>
  plumber::pr_run(port=8000)
```

``` bash
curl --data "x=0" "http://localhost:8000/try"
# --- Response body ---
# {"ts":"2022-10-16 14:08:00.00545",
# "ut":1665950880,
# "level":"INFO",
# "value":3,
# "title":"POST /try",
# "message":""}
# --- STDERR ---
# {"ts":"2022-10-16 14:08:00.006481",
# "ut":1665950880,
# "level":"SUCCESS",
# "value":4,
# "title":"Status 200: OK",
# "message":""}
```
