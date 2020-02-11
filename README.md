# bahelper

<!-- badges: start -->
[![R build status](https://github.com/maxheld83/bahelper/workflows/R-CMD-check/badge.svg)](https://github.com/maxheld83/bahelper/actions)
[![CRAN status](https://www.r-pkg.org/badges/version/bahelper)](https://CRAN.R-project.org/package=bahelper)
[![Codecov test coverage](https://codecov.io/gh/maxheld83/bahelper/branch/master/graph/badge.svg)](https://codecov.io/gh/maxheld83/bahelper?branch=master)
[![Lifecycle: experimental](https://img.shields.io/badge/lifecycle-experimental-orange.svg)](https://www.tidyverse.org/lifecycle/#experimental)
<!-- badges: end -->

This package is a very thin wrapper around [{httr}](https://httr.r-lib.org), [{getPass}](https://cran.r-project.org/web/packages/getPass/index.html) and [{keyring}](https://github.com/r-lib/keyring) for  [basic access authentication](https://en.wikipedia.org/wiki/basic_access_authentication) (BA) with username and password.

To access APIs from scripts, key and token authentication both more convenient and secure than BA (keys and tokens can be tightly scoped and revoked).
However, sometimes, only BA is available 😒.

The helpers in this package make BA a little easier to use.
They loosely follow {httr}'s advice on [managing secrets](https://httr.r-lib.org/articles/secrets.html):


#
## Installation

You can install the released version of {bahelper} from [GitHub](https://github.com/maxheld83/bahelper) with:

``` r
remotes::install_github("maxhed83/bahelper")
```


## Usage


## Interactive BA

Passwords should not be stored in R scripts, nor entered at the R console.
To avoid this, `getPass::getPass()` is used to prompt for your API password whenever necessary.

If possible, your API password is saved to your operating system (OS) keychain. 
On repeat authorisations, your API password will then be obtained from your system keychain.
Depending on your settings, you may then be prompted for your keychain (or OS login) password.
The system keychain offers better security than environment variables, because secrets are stored encrypted and access can be more tightly controlled.


### Non-Interactive BA

If an **environment variable** of the correct key (name) is found, it's value is used as the password.

This is best used only where interactive BA is impossible, or where there is at least some provision to keep environment variables secret, such as storing the password encrypted and separately from the scripts, and redacting the passwords from logs.
Such "secret" environment variables are supported on many cloud computing services (for example, [GitHub Actions](https://help.github.com/en/actions/configuring-and-managing-workflows/creating-and-storing-encrypted-secrets)).
