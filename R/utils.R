#' Find out the API framework
#' 
#' @param req The request object.
#' @param res The response object.
#' 
#' @return A character vector of length 1 with the name of the inferred
#'   R package or `NA` (which behaves as if it were Plumber).
#'   Unsupported frameworks will produce an error.
#' @noRd
api_framework <- function(req, res) {
    # plumber, RestRserve, fiery, ambiorix, beakr all use R6
    if (inherits(res, "R6")) {
        if (inherits(res, "PlumberResponse")) {
            # plumber's res class is PlumberResponse - specific enough
            # https://github.com/rstudio/plumber/blob/main/R/plumber-response.R
            # res=plumber:::PlumberResponse$new()
            return("plumber")
        }
        if (inherits(res, "Response") && identical(utils::capture.output(print(res))[1L], "<RestRserve Response>")) {
            # RestRserve's res class is Response & R6
            # https://github.com/rexyai/RestRserve/blob/master/R/Response.R
            # res=RestRserve::Response$new()
            return("RestRserve")
        }
        if (inherits(res, "Response") && identical(utils::capture.output(print(res))[1L], "A HTTP response")) {
            # fiery uses reqres https://github.com/thomasp85/reqres/blob/main/R/response.R
            # fake_rook <- fiery::fake_request(
            #   'http://example.com/test?id=34632&question=who+is+hadley',
            #   content = 'This is elaborate ruse',
            #   headers = list(
            #     Accept = 'application/json; text/*',
            #     Content_Type = 'text/plain'
            #   )
            # )
            # req <- reqres::Request$new(fake_rook)
            # res <- reqres::Response$new(req)
            # inherits(res, "Response") 
            # TRUE
            # utils::capture.output(print(res))
            # [1] "A HTTP response"                                                           
            # [2] "==============="                                                           
            # [3] "        Status: 404 - Not Found"                                           
            # [4] "  Content type: text/plain"                                                
            # [5] ""                                                                          
            # [6] "In response to: http://example.com:80/test?id=34632&question=who+is+hadley"
            stop("API framework not supported by tryr: fiery.")
        }
        if (inherits(res, "ambiorixResponse")) {
            # ambiorix https://github.com/devOpifex/ambiorix/blob/master/R/response.R
            # res <- ambiorix::response("")
            # inherits(res, "ambiorixResponse")
            stop("API framework not supported by tryr: ambiorix.")
        }
        if (inherits(res, "Response") && grepl("A Response", utils::capture.output(print(res),type = "message")[2L])) {
            # ambiorix https://github.com/devOpifex/ambiorix/blob/master/R/response.R
            # res <- ambiorix::response("")
            # inherits(res, "ambiorixResponse")
            # res <- ambiorix::Response$new()
            # utils::capture.output(print(res))[1]
            # grepl("A Response", utils::capture.output(print(res),type = "message")[2L])
            stop("API framework not supported by tryr: ambiorix.")
        }
        # beakr https://github.com/MazamaScience/beakr/blob/main/R/Response.R
        # res <- beakr::Response$new()
        # inherits(res, "Response")
        # utils::capture.output(print(res))
        stop("Unknown API framework, not supported by tryr.")
    }
    # unknown - behaves like Plumber
    NA_character_
}

#' Remove newlines and leading/trailing white space from a string
#' 
#' @param x A string, possibly a vector
#' 
#' @return An atomic character vector.
#' @noRd
one_line <- function(x) {
    trimws(gsub("[\r\n]", " ", paste(as.character(x), collapse = " ")))
}

#' Unbox a scalar like in jsonlite but not as safe
#' 
#' @param x An atomic vector
#' 
#' @return x when length > 1, and x as a scalar class when length is 1
#' @noRd
un_box <- function(x) {
    if (!identical(length(x), 1L))
        return(x)
    class(x) <- c("scalar", class(x))
    x
}
