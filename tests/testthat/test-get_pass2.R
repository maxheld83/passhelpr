test_that("password returns invisibly", {
  expect_invisible(call = {
    get_pass2(user = "foo", service = "bar", env_var = "PATH")
  })
})
test_that("password from env_var", {
  checkmate::expect_character(
    get_pass2(user = "foo", service = "bar", env_var = "PATH")
  )
  expect_error(object = {
    get_pass2(user = "foo", service = "bar", env_var = "asdasdasd")
  })
})
test_that("password from keychain", {
  skip_if_not(
    condition = Sys.info()["nodename"] == "Maximilians-MBP",
    message = "Test requires Max's keychain"
  )
  expect_equal(
    # password for the below keyring is also foo
    object = get_pass2(
      user = "info@maxheld.de",
      service = "testing.maxheld.de",
      keyring = "bahelper-testing"
    ),
    expected = "foo"
  )
})
test_that("password from prompt", {
  # because this does not work interactively
  expect_error(object = get_pass2(user = "foo", service = "bar"))
})
