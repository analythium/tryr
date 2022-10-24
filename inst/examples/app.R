#' Shiny app to explore the inst/examples/plumber.R API
#' 
#' The Shiny app is running at http://127.0.0.1:8080
#' The Plumber API is running at http://127.0.0.1:5000

library(shiny)

out <- file.path(tempdir(), "out")
err <- file.path(tempdir(), "err")
rx <- callr::r_bg(function() {
    FORMAT = "PLAIN" # PLAIN/JSON/CSV
    DIGITS = "3"   # 0, 2, 6, ...
    DEBUG = FALSE  # TRUE/FALSE
    Sys.setenv(
        TRYR_PROC_NAME = "Plumber",
        TRYR_ERR_LEVEL = "WARN",
        TRYR_LOG_FORMAT = FORMAT,
        TRYR_LOG_DIGITS = DIGITS
    )
    plumber::pr("inst/examples/plumber.R") |>
        plumber::pr_set_debug(DEBUG) |>
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
        plumber::pr_run(
            port = 5000,
            quiet = TRUE
        )
  },
  stdout = out, 
  stderr = err
)
Sys.sleep(1)

ui <- fluidPage(
    fluidRow(
        column(12,
            h2("Plumber API")
        ),
        column(4,
            radioButtons("endpoint", "Endpoint", c("/test", "/try"))
        ),
        column(4,
            textInput("value", "Value", "0")
        ),
        column(4,
            actionButton("button", "Post request", class="btn-info")
        )
    ),
    fluidRow(
        hr(),
        column(6,
            h3("REQ"),
            verbatimTextOutput("req")
        ),
        column(6,
            h3("RES"),
            verbatimTextOutput("res")
        )
    ),
    fluidRow(
        hr(),
        column(6,
            h3("STDOUT"),
            verbatimTextOutput("stdout")
        ),
        column(6,
            h3("STDERR"),
            verbatimTextOutput("stderr")
        )
    )
)

server <- function(input, output, session) {

    Cat <- function(x, n=8) {
        if (missing(x))
            x <- ""
        if (length(x) < 1L)
            x <- ""
        if (!identical(x, ""))
            x <- paste0("[", seq_along(x), "] ", x)
        if (length(x) < n)
            x <- c(x, rep("", n - length(x)))
        x <- tail(x, n)
        paste(x, "\n")
    }

    url <- reactive({
        paste0(
            "http://127.0.0.1:5000",
            input$endpoint,
            "?x=",
            input$value)
    })
    v <- reactiveValues(
        request = character(),
        response = character(),
        stdout = readLines(out),
        stderr = readLines(err)
    )
    observeEvent(input$button, {
        v$request <- c(v$request, url())
        r <- httr::POST(url())
        v$response <- c(v$response,
            httr::content(r, "text", "application/json", "UTF-8"))
        Sys.sleep(0.1)
        v$stdout <- readLines(out)
        v$stderr <- readLines(err)
    })

    output$req <- renderText({
        Cat(v$request)
    }, sep = "")
    output$res <- renderText({
        Cat(v$response)
    }, sep = "")
    output$stdout <- renderText({
        Cat(v$stdout)
    }, sep = "")
    output$stderr <- renderText({
        Cat(v$stderr)
    }, sep = "")

    onStop(fun = function() {
        rx$kill()
    })

}

shiny::shinyApp(ui, server) |> 
    shiny::runApp(port = 8080)
