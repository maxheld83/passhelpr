#' Get a password from an environment variable, keychain or prompt
#'
#' Gets a password, in this order, from:
#'
#' 1. `password`, unless it is `NULL` or `""` as for an unset variable.
#' 2. a password matching `user` and `service` in the system's keychain `keyring`.
#' 3. an interactive prompt.
#'
#' Otherwise, an error is thrown.
#'
#' @param user `[character(1)]` giving the username to authenticate with, for example `"jane"`.
#' Also used to retrieve from and store the password in `keyring`.
#'
#' @param password `[character(1)]` giving the password.
#' Use this to substitute in an environment variable such as `Sys.getenv("SECRET")`.
#' Recommended only when the environment variable is declared in an encrypted form, and when it is redacted from the logs.
#' **Do not expose your passwords in scripts or the R console.**
#' Defaults to `NULL`, in which case the `keyring` is used.
#'
#' @param service `[character(1)]` giving the service to authenticate against with `user` and `password`, for example `"foo-service.com"`.
#' Also used to retrieve from and store the password in `keyring`.
#' If a longer URL is provided, the domain is extracted using [urltools::domain()], which is the conventional name for storing secrets (for example, `"foo-service.com"`, not `"https://foo-service.com/api"`).
#'
#' @inheritParams keyring::key_set_with_value
#'
#' @export

get_pass2 <- function(user, password = NULL, service, keyring = NULL) {
  # prep and input validation
  checkmate::assert_string(x = user, null.ok = FALSE)
  checkmate::assert_string(x = password, null.ok = TRUE)
  checkmate::assert_string(x = service, null.ok = FALSE)
  # this gives the canonical way to store passwords under
  service <- urltools::domain(x = service)

  # body
  if (!is.null(password)) {
    if (password != "") {
      return(invisible(password))
    } else {
      usethis::ui_oops(c(
        usethis::ui_code(password), "was empty.",
        "Perhaps the environment variable was unset."
      ))
    }
  }
  usethis::ui_info("Trying to get password from system keychain ...")
  last_chance_non_ia <- all(
    can_keyring_system(),
    can_keyring_unlocked(keyring = keyring),
    can_pass_from_kc_found(user = user, service = service, keyring = keyring)
  )
  msg_pass_kc_sucess <- "Getting password from system keychain."
  if (last_chance_non_ia) {
    usethis::ui_done(msg_pass_kc_sucess)
    return(invisible(
      keyring::key_get(service = service, username = user, keyring = keyring)
    ))
  }
  if (!interactive()) {
    usethis::ui_stop("Could not get password without an interactive session.")
  }
  msg_pass_prompt_service <- paste(
    "Enter password for user", user, "on service", service, "..."
  )
  if (!can_keyring_system()) {
    usethis::ui_info("Password will not be saved.")
    usethis::ui_done("Getting password from prompt.")
    return(invisible(
      getPass::getPass(msg = msg_pass_prompt_service)
    ))
  }
  if (can_keyring_unlocked(keyring = keyring)) {
    lock_me_again <- FALSE  # leave keyrings in whatever state found
  } else {
    usethis::ui_todo("Please unlock they keyring.")
    keyring::keyring_unlock(
      keyring = keyring,
      password = getPass::getPass(
        msg = paste("Enter password for keyring", keyring, "...")
      )
    )
    usethis::ui_done("Keyring unlocked.")
    lock_me_again <- TRUE  # leave keyrings in whatever state found
  }
  if (can_pass_from_kc_found(user = user, service = service, keyring = keyring)) {
    usethis::ui_done(msg_pass_kc_sucess)
  } else {
    keyring::key_set_with_value(
      service = service,
      username = user,
      password = getPass::getPass(
        msg = msg_pass_prompt_service
      ),
      keyring = keyring
    )
    usethis::ui_done("Password saved to keyring.")
  }
  usethis::ui_done("Getting password from keychain.")
  invisible(keyring::key_get(service = service, keyring = keyring, username = user))
}

can_keyring_system <- function() {
  if (keyring::has_keyring_support()) {
    TRUE
  } else {
    usethis::ui_oops("The system does not support keyring access.")
    FALSE
  }
}

can_keyring_unlocked <- function(keyring = keyring) {
  if (keyring::keyring_is_locked(keyring = keyring)) {
    usethis::ui_oops("The keyring is locked.")
    FALSE
  } else {
    TRUE
  }
}

can_pass_from_kc_found <- function(user, service, keyring = keyring) {
  all_users <- keyring::key_list(service = service, keyring = keyring)$username
  if (user %in% all_users) {
    TRUE
  } else {
    usethis::ui_oops(
      "A password for user {user} on service {service} could not be found in the keyring."
    )
    FALSE
  }
}
