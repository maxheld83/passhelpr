# bahelper

<!-- badges: start -->
[![R build status](https://github.com/maxheld83/bahelper/workflows/R-CMD-check/badge.svg)](https://github.com/maxheld83/bahelper/actions)
[![CRAN status](https://www.r-pkg.org/badges/version/bahelper)](https://CRAN.R-project.org/package=bahelper)
[![Codecov test coverage](https://codecov.io/gh/maxheld83/bahelper/branch/master/graph/badge.svg)](https://codecov.io/gh/maxheld83/bahelper?branch=master)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
<!-- badges: end -->

This packages gets passwords for [basic access authentication](https://en.wikipedia.org/wiki/basic_access_authentication) (BA, using username and password).
In this order, it gets them from environment variables, system keychains and interactive prompts.

To access APIs from scripts, key and token authentication are both more convenient and secure than BA (keys and tokens can be tightly scoped and revoked).
You should use it over this whenever you can.
However, sometimes, only BA is available 😒.

Using BA can be a bit cumbersome, especially when developing on different computers and servers.
The helpers in this package make BA a little easier to use, by looking in several places in turn.

They loosely follow {httr}'s advice on [managing secrets](https://httr.r-lib.org/articles/secrets.html).

This package is a very thin wrapper around [{httr}](https://httr.r-lib.org), [{getPass}](https://cran.r-project.org/web/packages/getPass/index.html) and [{keyring}](https://github.com/r-lib/keyring).


## Installation

You can install the released version of {bahelper} from [GitHub](https://github.com/maxheld83/bahelper) with:

``` r
remotes::install_github("maxhed83/bahelper")
```


## Usage

You can use `getpass2()` wherever you need a password for BA.
It will return the password invisibly.

```r
bahelper::get_pass2(
  user = "jane@foo-service.com", 
  service = "foo-service.com", 
  env.var = "${{secrets.FOO_SERVICE_PW}}"
)
```

This call should work on your local machine, someone elses computer and a CI server with minimal setup.

In this order, `get_pass2()` will:

1. Try to get the password from the specified **`env_var`**.
  If an environment variable of the name (key) `env_var` is set, it's content (value) will be returned as a password.
  You can use this for authenticating on a server, or in another non-interactive setting, where you cannot type in a password.
  However, you may want to rely on this when there is *some* protection for the environment variable.
  For example, it may be stored separately and encrypted, and it may be redacted from logs.
  Such "secret" environment variables are supported on many cloud computing services (for example, [GitHub Actions](https://help.github.com/en/actions/configuring-and-managing-workflows/creating-and-storing-encrypted-secrets)).
2. If `env_var = NULL` or the environment variable is unset, `get_pass2()` will **check the operating system keychain**.
  If necessary, you will be asked to unlock the `keyring` on your system keychain.
  `The system keychain offers better security than (unprotected) environment variables, because secrets are stored encrypted and access can be more tightly controlled.
  If there is a password for `service` and `user` in the `keyring`, it will be returned.
  `keyring=NULL` will use your default system keyring (typically something like "login").
3. If there is no matching password, or if the keychain cannot be used, you will be **prompted** to enter your password.
  The password will be saved in the `keyring` under `service` and `user` for future use.

The function is pretty chatty and keeps you informed on what is happening
