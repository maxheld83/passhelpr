# passhelpr

<!-- badges: start -->
[![R build status](https://github.com/maxheld83/passhelpr/workflows/CICD/badge.svg)](https://github.com/maxheld83/passhelpr/actions)
[![CRAN status](https://www.r-pkg.org/badges/version/passhelpr)](https://CRAN.R-project.org/package=passhelpr)
[![Codecov test coverage](https://codecov.io/gh/maxheld83/passhelpr/branch/master/graph/badge.svg)](https://codecov.io/gh/maxheld83/passhelpr?branch=master)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
<!-- badges: end -->

This packages gets passwords for [basic access authentication](https://en.wikipedia.org/wiki/basic_access_authentication) (BA, using username and password).
In this order, it gets them from environment variables, system keychains and interactive prompts.


## Installation

You can install the released version of {passhelpr} from [GitHub](https://github.com/maxheld83/passhelpr) with:

``` r
remotes::install_github("maxhed83/passhelpr")
```


## Usage

Let's say you need to access an API from `foo-service.com` in your script which only offers BA.
Your username is `jane@foo-service.com` and your password is `bar` (bad, I know).
You want your script to work on your local development machine, but without entering your password on every run, so you'd like the password to be saved in your system keychain.
You also want it to work on a cloud service, so you store your password as a secret environment variable in the cloud service UI.
For example, you set `${{secrets.FOO_SERVICE_PW))}}` to `bar` using [GitHub Actions secret environment variables](https://help.github.com/en/actions/configuring-and-managing-workflows/creating-and-storing-encrypted-secrets).

Depending on where your script is running, and whether you've authenticated before, you need to retrieve your password `bar` from different places.

`get_pass2()` figures it out for you, and returns the password invisibly.

```r
passhelpr::get_pass2(
  user = "jane@foo-service.com", 
  service = "foo-service.com", 
  env.var = "${{secrets.FOO_SERVICE_PW}}"
)
```

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


## Caveats

To access APIs from scripts, key and token authentication are both more convenient and secure than BA (keys and tokens can be tightly scoped and revoked).
You should use instead of BA whenever you can.


## Links

The package closely follows {httr}'s advice on [managing secrets](https://httr.r-lib.org/articles/secrets.html).

The package is a very thin wrapper around [{httr}](https://httr.r-lib.org), [{getPass}](https://cran.r-project.org/web/packages/getPass/index.html) and [{keyring}](https://github.com/r-lib/keyring).
