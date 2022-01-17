# ss-payout

Calculate your U.S. Social Security retirement payout.

## Usage

```
Usage: ss-payout.sh [flags]
Option flags:
  -b --dob       - Date of Birth. Default: '1976.07.04'.
  -m --monthly   - Monthly amount. Default: '1234'.
  -s --age-start - Age to start. Default: '70'.
  -e --age-end   - Age to end. Default: '90'.
  -c --config    - Configuration file. Default: 'ss-payout.conf.sample'.
  -h --help      - Show this help and exit.
  -v --verbose   - Verbose execution. Default: ''.
  -g --debug     - Extra verbose execution. Default: ''.
Info:
  Project Home: https://github.com/glevand/ss-payout
```

## Config File

A typical config file.

```
# Sample ss-payout configuration file.
# https://github.com/glevand/ss-payout
#

dob_full="${dob_full:-1976.07.04}"
monthly="${monthly:-1234}"
age_start="${age_start:-70}"
age_end="${age_end:-90}"
```

## Typical Output

```
SS Payout -- 2022.01.16-18.24.46

dob:              1976.07.04
today:            2022.01.16

payout start age: 70
payout start:     2046.07.04
payout start:     294 months

payout end age:   90
payout end:       2067.07.04
payout end:       546 months

payout duration:  252 months
payout amount:    $1234 per month

month 252:        2067.6  = $310968
```

## Licence & Usage

All files in the [ss-payout project](https://github.com/glevand/ss-payout), unless
otherwise noted, are covered by an
[MIT Plus License](https://github.com/glevand/ss-payout/blob/master/mit-plus-license.txt).
The text of the license describes what usage is allowed.

