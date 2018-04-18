# Contactor
> Manage contacts from the command line via the macOS Contacts framework.

Swift module utilizing the [Contacts Framework](https://developer.apple.com/documentation/contacts) to search, add and export contacts in various formats (VCF, text, CSV).

Module relies on the Contacts Framework, and is therefore only supported on macOS version 10.11+.

## Installation
```sh
$ brew tap kettle/homebrew-kettle
$ brew install Contactor
```

## Building from source
```sh
$ git clone git@github.com:kettle/Contactor.git && ./Contactor/build.sh prod
```

_* if no argument is passed to `build.sh`, the produced binary will be a `debug` build._

This should create the executable `/usr/local/bin/Contactor`.

## Usage
Run the binary without any arguments to see usage.

```
Usage: Contactor <command> [options]

Contactor - manage contacts via the command line

Commands:
  add             Add a contact
  list            List all contacts
  exists          Check if contact exists
  search          Search contacts
  help            Prints this help information
  version         Prints the current version of this app
```

For command-specific help, enter the command name followed by `--help`

```
$ Contactor add --help

Usage: Contactor add [options]

Options:
  -a, --street <value>        Contact street address
  -b, --birthday <value>      Contact birth day
  -c, --city <value>          Contact city
  -e, --email <value>         Email addresses (separated by ',')
  -f, --first <value>         Contact first name
  -h, --help                  Show help information for this command
  -l, --last <value>          Contact last name
  -m, --birthmonth <value>    Contact birth month
  -p, --pic <value>           Contact photo
  -s, --state <value>         Contact state
  -t, --telephone <value>     Phone numbers (seperated by ',')
  -z, --zip <value>           Contact zip code

Must pass at least one of the following: --first --last
```

Another example...

```
$ Contactor search --help

Usage: Contactor search <search> [options]

Options:
  -c, --csv             Write output to stdout in CSV format
  -f, --file <value>    Write output to individual VCF files in directory <value>
  -h, --help            Show help information for this command
  -t, --text            Write output to stdout as text (default)
  -v, --vcf             Write output to stdout in VCF format
```
