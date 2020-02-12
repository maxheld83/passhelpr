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

Let's say you need to access an API from `foo-service.com` in your script and the API only offers BA.
Your username is `alice` and your password is `bar` (bad, I know).
You want your script to work on your local development machine, but without entering your password on every run, so you'd like the password to be saved in your system keychain.
You also want it to work on a server, to which you pass your password as an environment variable `SECRET`.
Lastly, you may want the script to work on a cloud service, which allows you to declare special secret environment variables.

```r
passhelpr::get_pass2(
  user = "alice", 
  password = Sys.getenv("SECRET"),
  service = "foo-service.com"
)
```

In this order, `get_pass2()` will:

1. **Return `password`**, unless it is `NULL` or `""`, as would be the case for an unset environment variable.
  You can use this to get your password from an environment variable, by calling `Sys.getenv()`.
  
  You can use this for authenticating your script from a server, or in another non-interactive setting, where you cannot type in a password.
  Make sure that you safely declare the environment variable, and be aware that it may be accessible to other processes.
  
  You can, of course, also just pass your password, though that would defeat the purpose of this package.
  Remember not to store sensitive passwords in your scripts or enter it at the R console without a masked prompt.
2. If `password` is `NULL` or `""`, `get_pass2()` will **check the operating system keychain**.
  If necessary, you will be asked to unlock the `keyring` on your system keychain.
  The system keychain offers better security than environment variables, because secrets are stored encrypted and access can be more tightly controlled.
  If there is a password for `service` and `user` in the `keyring`, it will be returned.
  `keyring=NULL` will use your default system keyring (typically something like "login").
3. If there is no matching password, or if the keychain cannot be used, you will be **prompted** to enter your password.
  The password will be saved in the `keyring` under `service` and `user` for future use.

The function is pretty chatty and keeps you informed on what is happening


### Usage on Cloud Services (GitHub Actions)

Some cloud services provide better protection for "secret" environment variables.
For example, they may be entered separately in a web UI, stored in encrypted form and be redacted from logs and output.
Whenever possible, you should use these protected environment variables.

To use them in `get_pass2()`, you must know how to pass these special environment variables to your script as `password`.
The syntax and features may differ depending on the cloud vendor.

As an example, consider GitHub Actions.
GitHub Actions supports storing [secret environment variables](https://help.github.com/en/actions/configuring-and-managing-workflows/creating-and-storing-encrypted-secrets) in the repository settings, and then passing them to your script using the [contexts and expression syntax for GitHub Actions](https://help.github.com/en/actions/reference/contexts-and-expression-syntax-for-github-actions).
This syntax is always surrounded with double braces `{{ }}`.
Remember that the contexts and expression syntax is *only available in `*.yml` workflow files*.
You must therefore pass down the password from the secret environment format all the way down from the workflow file.

For example, let's assume you stored your password on GitHub as `EXAMPLE_SECRET`.

```yaml
on: push

jobs:
  myjob:
    step:
      - name: get password
        run: Rscript -e "passhelpr::get_pass2(user = 'alice', password = '${{ secrets.EXAMPLE_SECRET  }}', service = 'foo-service.com')"
```

If you need to use your password somewhere inside your script, you can also *declare* a new (unprotected) environment variable from the GitHub Actions yaml.
This may however contravene some of the protections around secret environment variables.

```yaml
on: push

jobs:
  myjob:
    step:
      - name: get password
        run: Rscript -e "passhelpr::get_pass2(user = 'alice', password = Sys.getenv('EXAMPLE_SECRET'), service = 'foo-service.com')"
        env:
          EXAMPLE_SECRET: ${{ secrets.EXAMPLE_SECRET }}
```


## Caveats

To access APIs from scripts, key and token authentication are both more convenient and secure than BA (keys and tokens can be tightly scoped and revoked).
Use it whenever you can.

The package closely follows {httr}'s advice on [managing secrets](https://httr.r-lib.org/articles/secrets.html).
To learn more about keeping your secrets safe, read that vignette.


## Thanks

The package is a very thin wrapper around [{httr}](https://httr.r-lib.org), [{getPass}](https://cran.r-project.org/web/packages/getPass/index.html) and [{keyring}](https://github.com/r-lib/keyring).
