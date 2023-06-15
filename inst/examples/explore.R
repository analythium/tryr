#' Shiny app to explore the inst/examples/plumber.R API
#' 
#' The Shiny app is running at http://127.0.0.1:8080
#' The Plumber API is running at http://127.0.0.1:5000

# Edit this function to reflect your Plumber API
plumber_fun <-function() {
    FORMAT = "PLAIN" # PLAIN/JSON/CSV
    DIGITS = "2"   # 0, 2, 6, ...
    DEBUG = FALSE  # TRUE/FALSE
    Sys.setenv(
        TRYR_LOG_FORMAT = FORMAT,
        TRYR_LOG_DIGITS = DIGITS
    )
    plumber::pr("inst/examples/plumber.R") |>
        plumber::pr_filter("cors", function(req, res) {
            res$setHeader("Access-Control-Allow-Origin", "*")
            plumber::forward()
        }) |>
        plumber::pr_set_debug(DEBUG) |>
        plumber::pr_set_404(
            function(req, res) {
                tryr::msg(
                    title = paste0(
                        "Status 404: ", 
                        tryr::http_status_codes["404", "message"]),
                    level = "INFO"
                )
                tryr::http_handler(req, res, 404L)
            }
        ) |>
        plumber::pr_set_error(
            function(req, res, err) {
                tryr::msg(
                    title = paste0(
                        "Status 500: ", 
                        tryr::http_status_codes["500", "message"]),
                    message = err,
                    level = "ERROR"
                )
                tryr::http_handler(req, res, 500L)
            }
        ) |>
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
}

library(shiny)
out <- file.path(tempdir(), "out")
err <- file.path(tempdir(), "err")
rx <- callr::r_bg(plumber_fun,
  stdout = out, 
  stderr = err
)
Sys.sleep(1)

ui <- fluidPage(
    theme = bslib::bs_theme(version = 5),
    tags$head(
        tags$style(HTML("
        .sidebar-section {
            height: 50vh;
            overflow: hidden;
        }
        .iframe-container {
            height: 100vh;
            overflow: hidden;
        }
        .iframe-container iframe {
            border: 0;
            height: 100%;
            width: 100%;
        }"))
    ),
    fluidRow(
        column(6,
            tags$div(
                tags$iframe(
                    src="http://127.0.0.1:5000/__docs__/"
                ),
                class="iframe-container"
            )
        ),
        column(6,
            tags$div(
                h3("STDOUT"),
                verbatimTextOutput("stdout"),
                class="sidebar-section"
            ),
            hr(),
            tags$div(
                h3("STDERR"),
                verbatimTextOutput("stderr"),
                class="sidebar-section"
            )
        )
    )
)

server <- function(input, output, session) {

    Cat <- function(x, n=10) {
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
    autoInvalidate <- reactiveTimer(250)

    v <- reactiveValues(
        stdout = readLines(out),
        stderr = readLines(err)
    )
    observe({
        autoInvalidate()
        v$stdout <- readLines(out)
        v$stderr <- readLines(err)
    })

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
