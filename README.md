# ebuild-bumper.sh
Experimental script for version bumping groups of related ebuilds. The 
script can also clean out older versions of the same group of related 
ebuilds. It can clean as it goes, but that is not safe for groups, as 
it will break the depgraph and cause the script the exit after repoman 
fails.

## Usage
The script functions off 5 variables, all pretty self explanatory. Place 
the variables in a file of its own in any location you choose. Default 
location is in the provided bump_pkg directory. That file is passed to 
ebuild-bumper.sh along with other arguments.

```bash
# Repo location
REPO="/usr/portage/local/os-xtoo"

# Package category, ommit and add to package name for different categories
CAT="dev-java"

# Base package name, ommit and add to package name for different preffixes
BASE="scribejava-"

# Deps to merge before the package, since using -O1
DEPS=""

# List of packages to bump/clean, order matters
PKGS=(
        core
        apis
)
```

To run see the following options

```bash
Ebuild bumper
Copyright 2016 Obsidian-Studios, Inc.
Distributed under the terms of The GNU Public License v3.0 (GPLv3)

 Global Options:
  -c, --clean                Clean/remove old version
  -C, --clean-all            Clean/remove all old versions
  -f, --file                 File to source for package specific variables
  -n, --new-version          New package version string, numeric or
                             alpha/numeric
  -o, --old-version          Old/current package version string, numeric or
                             alpha/numeric
  -r, --resume               Resume at array index, numeric only!
  -v, --verbose              Enable verbose commands

 GNU Options:

  -?, --help                 Give this help list
      --usage                Give a short usage message
  -V, --version              Print program version
```
