#' Find out the API framework
#' 
#' @param req The request object.
#' @param res The response object.
#' 
#' @return A character vector of length 1.
#'   Possible values: `"plumber"`, `"RestRserve"` (R package names);
#'   `"plumber"` is assumed when the API framework cannot be determined.
api_framework <- function(req, res) {
    # RestRserve's res class is Response & R6
    if (inherits(res, "Response"))
        return("RestRserve")
    # plumber's res class is PlumberResponse & R6
    # would probably work for firey & ambiorix
    # would probably fail with beakr
    "plumber"
}


