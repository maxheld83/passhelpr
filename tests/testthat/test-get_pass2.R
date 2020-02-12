test_that("password returns invisibly", {
  expect_invisible(call = {
    get_pass2(user = "doesnotexist", password = "bar", service = "foo-service.com")
  })
})
test_that("password from env_var", {
  checkmate::expect_character(
    get_pass2(
      user = "doesnotexist",
      password = Sys.getenv("PATH"),
      service = "foo-service.com"
    )
  )
  expect_error(object = {
    get_pass2(
      user = "doesnotexist",
      password = Sys.getenv("DOESNOTEXISTASDASD"),
      service = "foo-service.com"
    )
  })
})
test_that("password from GitHub Actions", {
  skip_if_not(condition = file.exists("/github/workflow/event.json"))
  expect_equal(
    # password for the below keyring is also foo
    object = get_pass2(
      user = "doesnotexist",
      password = Sys.getenv("EXAMPLE_SECRET"),
      service = "foo-service.com"
    ),
    expected = "baz"
  )
})
test_that("password from keychain", {
  skip_if_not(
    condition = Sys.info()["nodename"] == "Maximilians-MBP",
    message = "Test requires Max's keychain"
  )
  expect_equal(
    # password for the below keyring is also foo
    object = get_pass2(
      user = "bob",
      service = "foo-service.com",
      keyring = "passhelpr-testing3"
    ),
    expected = "foo"
  )
})
test_that("password from prompt", {
  # because this does not work interactively
  expect_error(object = get_pass2(user = "doesnotexist", service = "foo-service.com"))
})
