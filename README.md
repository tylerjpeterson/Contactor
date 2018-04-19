# Contactor
> Manage contacts from the command line via the macOS Contacts framework.

Swift module utilizing the [Contacts Framework](https://developer.apple.com/documentation/contacts) to search, add, remove and export contacts in various formats (VCF, text, CSV).
This module requires the Contacts Framework, and is therefore only supported on macOS version 10.12+.

## Installation
```sh
$ brew tap kettle/homebrew-kettle
$ brew install Contactor
```

## Building from source
```sh
$ git clone git@github.com:kettle/Contactor.git && ./Contactor/build.sh prod
```

The newly compiled executable will be written to `/usr/local/bin/Contactor`.
This may trip up homebrew.
To avoid any issues, it's recommended that you remove any homebrew-installed versions of Contactor before building from source.

```
$ brew remove Contactor
```


## Usage
Run the executable without any arguments to output usage options.

```
Usage: Contactor <command> [options]

Contactor - manage contacts via the command line

Commands:
  add             Add a contact
  list            List all contacts
  exists          Check if contact exists
  search          Search contacts
  remove          Remove a contact
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
  -d, --dir <value>     Write output to individual VCF files in directory <value>
  -h, --help            Show help information for this command
  -t, --text            Write output to stdout as text (default)
  -v, --vcf             Write output to stdout in VCF format
```

## Output formats
You can control the output of matched contacts by passing flags to the search and list commands.
Generally output is sent to stdout where it can be handled accordingly.

### CSV
To write matched results to a CSV file:

```
$ Contactor list -c > ~/Desktop/contacts.csv
```

### Text
To write matched results as a text string with one property on each line preceded by the property name:

```
$ Contactor list
```

### VCF files
There are two ways to generate VCF files from Contactor.
The first is to set the "dir" parameter to the directory where you want to save your VCF files.
Contactor will generate a VCF file for each matched contact at that location.

```
$ Contactor search -d ~/Desktop "Appleseed"
```

The second approach outputs base-64 encoded VCF data for all matching contacts to stdout.
This allows you to easily export all contacts as a single, combined VCF file.
Simply pass the command the "v" flag and capture the output.

Note, this file may be quite large as all Contact photos are written within the file as base-64-encoded strings.

```
$ Contactor list -v > ~/Desktop/all-contacts.vcf
```

## Included scripts
There are a number of shell and ruby scripts in `./bin`.
The purpose of each is outlined below.

#### build.sh
Compiles the module into both a framework and executable.
The executable is stored in `/usr/local/bin/Contactor` upon completion.
Running the command without any arguments generates a development build.
Running the command with the argument `prod` (as illustrated below) will generate a production build.

```
$ bin/build.sh prod
```

#### config.rb
This script recursively updates build settings within a generated `xcodeproj` project.
This is necessary to quiet compiler errors due to dependencies supporting versions of macOS prior to version `10.12`.

#### docs.sh
Uses [Jazzy](https://github.com/realm/jazzy) to generate module documentation.
This script also lints the Swift files using [SwiftLint](https://github.com/realm/SwiftLint).

#### Info.template.plist
Template file for generating an updated plist when a new version is authored.

#### release.sh
Script to automate the creation of a production build for a particular version.
This script also creates a "release" on GitHub, and uploads the most recently generated binary as the release asset.
The script expects one argument which indicates the version of the release.
For example:

```
$ bin/release.sh 1.0.0
```

#### release.template.rb
Another simple template to generate the Contactor homebrew formula and publish it to GitHub.

#### xcode.sh
This script generates a traditional Xcode project.
This can be useful during development.
The generated Xcode project is not kept in version control.
Changes anything other than the contents of the `Sources` directory should be considered ephemeral.
