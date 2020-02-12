#' Use http authentication from environment variable, keychain or prompt
#' Wraps [httr::authenticate()] for convenience.
#' See [get_pass2()] for details.
#'
#' @inheritParams httr::authenticate
#'
#' @inheritParams get_pass2
#'
#' @details
#' Key and token-based authentication is more secure and convenient; use basic authentication (BA, aka. username and password) only if unavoidable and at your own risk.
#' Read the {httr} vignette on [managing secrets](https://httr.r-lib.org/articles/secrets.html) for details.
#'
#' @export
authenticate2 <- function(user,
                          password = NULL,
                          type = "basic",
                          service,
                          keyring = NULL) {
  httr::authenticate(
    user = user,
    password = get_pass2(
      user = user,
      password = password,
      service = service,
      keyring = keyring
    ),
    type = type
  )
}
