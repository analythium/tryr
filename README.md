# tryr: Client/Server Error Handling for Plumber APIs

``` r
remotes::install_github("analythium/tryr")
```

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
  plumber::pr_set_debug(FALSE) |>
  plumber::pr_run(port=8000)
```

### Default behavior

We use a very simple handler calling the function `foo()`: note that the
contents of the response also depend on the `pr_set_debug()` settings
that depends on whether we use interactive or non-interactive session.
Therefore we turned that off in our interactive examples.

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

    # --- Request ---
    # curl -X POST "http://localhost:8000/test?x=0"
    # --- Response ---
    # ["Success!"]
    # --- STDOUT ---
    # 
    # --- STDERR ---
    # Running plumber API at http://127.0.0.1:8000
    # Running swagger Docs at http://127.0.0.1:8000/__docs__/

    # --- Request ---
    # curl -X POST "http://localhost:8000/test?x=-1"
    # --- Response ---
    # {"error":"500 - Internal server error"}
    # --- STDOUT ---
    # <simpleError in foo(x = x): 'x' is too low.>
    # --- STDERR ---
    # Running plumber API at http://127.0.0.1:8000
    # Running swagger Docs at http://127.0.0.1:8000/__docs__/

    # --- Request ---
    # curl -X POST "http://localhost:8000/test?x=a"
    # --- Response ---
    # {"error":"500 - Internal server error"}
    # --- STDOUT ---
    # <simpleError in if (x < 0) stop("'x' is too low."): missing value where TRUE/FALSE needed>
    # --- STDERR ---
    # Running plumber API at http://127.0.0.1:8000
    # Running swagger Docs at http://127.0.0.1:8000/__docs__/
    # Warning in foo(x = x) : NAs introduced by coercion

    # --- Request ---
    # curl -X POST "http://localhost:8000/test?x="
    # --- Response ---
    # {"error":"500 - Internal server error"}
    # --- STDOUT ---
    # <simpleError in foo(x = x): argument "x" is missing, with no default>
    # --- STDERR ---
    # Running plumber API at http://127.0.0.1:8000
    # Running swagger Docs at http://127.0.0.1:8000/__docs__/

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
  x <- suppressWarnings(as.numeric(x))
  if (is.na(x))
    tryr::http_error(400L, "Unexpected input.")
  foo(x)
}

#* @post /try
function(req, res, x) {
  tryr::http_try(req, res, {
    if (missing(x))
      stop("'x' is missing", call. = FALSE)
    bar(x = x)
  })
}
```

Here are the outputs from the `/try` endpoint:

    # --- Request ---
    # curl -X POST "http://localhost:8000/try?x=0"
    # --- Response ---
    # ["Success!"]
    # --- STDOUT ---
    # 2022-10-21 11:44:17.93 [SUCCESS] Status 200: OK
    # --- STDERR ---
    # Running plumber API at http://127.0.0.1:8000
    # Running swagger Docs at http://127.0.0.1:8000/__docs__/

    # --- Request ---
    # curl -X POST "http://localhost:8000/try?x=-1"
    # --- Response ---
    # {"category":"Server Error","status":500,"message":"Internal Server Error"}
    # --- STDOUT ---
    # 
    # --- STDERR ---
    # Running plumber API at http://127.0.0.1:8000
    # Running swagger Docs at http://127.0.0.1:8000/__docs__/
    # 2022-10-21 11:44:19.00 [ERROR  ] Status 500: Internal Server Error - Error in foo(x) : 'x' is too low.

    # --- Request ---
    # curl -X POST "http://localhost:8000/try?x=a"
    # --- Response ---
    # {"category":"Client Error","status":400,"message":"Bad Request - Unexpected input."}
    # --- STDOUT ---
    # 
    # --- STDERR ---
    # Running plumber API at http://127.0.0.1:8000
    # Running swagger Docs at http://127.0.0.1:8000/__docs__/
    # 2022-10-21 11:44:20.07 [ERROR  ] Status 400: Bad Request - Unexpected input.

    # --- Request ---
    # curl -X POST "http://localhost:8000/try?x="
    # --- Response ---
    # {"category":"Server Error","status":500,"message":"Internal Server Error"}
    # --- STDOUT ---
    # 
    # --- STDERR ---
    # Running plumber API at http://127.0.0.1:8000
    # Running swagger Docs at http://127.0.0.1:8000/__docs__/
    # 2022-10-21 11:44:21.14 [ERROR  ] Status 500: Internal Server Error - Error : 'x' is missing

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
  plumber::pr_set_debug(FALSE) |>
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

Output:

    # --- Request ---
    # curl -X POST "http://localhost:8000/try?x=0"
    # --- Response ---
    # ["Success!"]
    # --- STDOUT ---
    # {"ts":"2022-10-21 11:44:22.190643","ut":1666374262.19064,"level":"INFO","value":3,"title":"POST /try","message":""}
    # {"ts":"2022-10-21 11:44:22.219624","ut":1666374262.21962,"level":"SUCCESS","value":4,"title":"Status 200: OK","message":""}
    # --- STDERR ---
    # Running plumber API at http://127.0.0.1:8000
    # Running swagger Docs at http://127.0.0.1:8000/__docs__/

    # --- Request ---
    # curl -X POST "http://localhost:8000/try?x=-1"
    # --- Response ---
    # {"category":"Server Error","status":500,"message":"Internal Server Error"}
    # --- STDOUT ---
    # {"ts":"2022-10-21 11:44:23.262025","ut":1666374263.26203,"level":"INFO","value":3,"title":"POST /try","message":""}
    # --- STDERR ---
    # Running plumber API at http://127.0.0.1:8000
    # Running swagger Docs at http://127.0.0.1:8000/__docs__/
    # {"ts":"2022-10-21 11:44:23.289186","ut":1666374263.28919,"level":"ERROR","value":6,"title":"Status 500: Internal Server Error","message":"Error in foo(x) : 'x' is too low."}

    # --- Request ---
    # curl -X POST "http://localhost:8000/try?x=a"
    # --- Response ---
    # {"category":"Client Error","status":400,"message":"Bad Request - Unexpected input."}
    # --- STDOUT ---
    # {"ts":"2022-10-21 11:44:24.337541","ut":1666374264.33754,"level":"INFO","value":3,"title":"POST /try","message":""}
    # --- STDERR ---
    # Running plumber API at http://127.0.0.1:8000
    # Running swagger Docs at http://127.0.0.1:8000/__docs__/
    # {"ts":"2022-10-21 11:44:24.367991","ut":1666374264.36799,"level":"ERROR","value":6,"title":"Status 400: Bad Request - Unexpected input.","message":""}

    # --- Request ---
    # curl -X POST "http://localhost:8000/try?x="
    # --- Response ---
    # {"category":"Server Error","status":500,"message":"Internal Server Error"}
    # --- STDOUT ---
    # {"ts":"2022-10-21 11:44:25.424462","ut":1666374265.42446,"level":"INFO","value":3,"title":"POST /try","message":""}
    # --- STDERR ---
    # Running plumber API at http://127.0.0.1:8000
    # Running swagger Docs at http://127.0.0.1:8000/__docs__/
    # {"ts":"2022-10-21 11:44:25.455751","ut":1666374265.45575,"level":"ERROR","value":6,"title":"Status 500: Internal Server Error","message":"Error : 'x' is missing"}

Structured errors are handled by the `http_error()` function that uses
default error messages as defined in the `http_status_codes` data frame.

The `http_success()` works similarly but it does not produce an error.
It can also pass a `body` argument. This is useful if we need to return
simple status messages when responding to webhooks during async
execution.

## Readings

<https://cran.r-project.org/web/packages/tryCatchLog/vignettes/tryCatchLog-intro.html>

## Considerations

STDOUT is buffered, needs a flush. STDERR is unbuffered, more immediate
<https://unix.stackexchange.com/questions/331611/do-progress-reports-logging-information-belong-on-stderr-or-stdout>

But the API does not fail
