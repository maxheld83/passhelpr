#' Get a password from an environment variable, keychain or prompt
#'
#' If `env_var` is found, it's value is used as a password.
#' If `env_var` is unset (`""`) or if `env_var` is `NULL`, a password matching `user` and `service` in `keyring` is used.
#' If no password in the `keyring` is found, the keychain unavailable or locked but the session is interactive, a prompt is opened.
#' Otherwise, an error is thrown.
#'
#' @inheritParams httr::authenticate
#'
#' @param service `[character(1)]` giving the service to authenticate against, such as `"www.foo.com"`.
#' Used for retrieving from, and storing the secret to they `keyring`.
#' If a longer URL is provided, the domain is extracted using [urltools::domain()], which is the conventional name for storing secrets (for example, `"www.fooservice.com"`.).
#'
#' @inheritParams keyring::key_set_with_value
#'
#' @param env_var `[character(1)]` giving the key (name) to the environment variable under which the password is stored.
#' Recommended only when the environment variable is declared in an encrypted form, and when it is redacted from the logs.
#' Use with extreme caution.
#' Defaults to `NULL`, in which case the password is prompted.
#'
#' @export

get_pass2 <- function(user, service, keyring = NULL, env_var = NULL) {
  # prep and input validation
  checkmate::assert_string(x = user, null.ok = FALSE)
  checkmate::assert_string(x = service, null.ok = FALSE)
  # this gives the canonical way to store passwords under
  service <- urltools::domain(x = service)
  checkmate::assert_string(x = env_var, null.ok = TRUE)

  # body
  if (!is.null(env_var)) {
    usethis::ui_info(
      "Trying to get password from environment variable {env_var} ..."
    )
    if (can_pass_from_env_var(env_var = env_var)) {
      usethis::ui_done("Getting password from environment variable {env_var}.")
      return(invisible(Sys.getenv(env_var)))
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

can_pass_from_env_var <- function(env_var) {
  if (Sys.getenv(env_var) == "") {
    usethis::ui_oops(
      "Could not get password from environment variable {env_var} because it was unset.",
    )
    FALSE
  } else {
    TRUE
  }
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
