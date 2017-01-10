# ebuild-bumper.sh
[![License](https://img.shields.io/badge/license-GPLv3-9977bb.svg?style=plastic)](https://github.com/Obsidian-StudiosInc/ebuild-bumper/blob/master/LICENSE)
[![Build Status](https://img.shields.io/travis/Obsidian-StudiosInc/ebuild-bumper/master.svg?colorA=9977bb&style=plastic)](https://travis-ci.org/Obsidian-StudiosInc/ebuild-bumper)
[![Build Status](https://img.shields.io/shippable/5840e5d7e2ab4d0f0058b4b3/master.svg?colorA=9977bb&style=plastic)](https://app.shippable.com/projects/5840e5d7e2ab4d0f0058b4b3/)

A bash script for version bumping an individual ebuild or groups of 
ebuilds with the same version. The script can also clean out older 
versions of the same group ebuilds, or single ebuild version. It can 
clean as it goes, but that is only save for individual packages. If  
cleaning as part of a group of packages being bumped, it will break the 
depgraph. Which will cause the script to exit when repoman fails.

## Usage
There is two ways to use the script, directly on a single package, or 
using a bump file that provides the necessary variables for multiple 
packages.

### Single package
To bump a single package
```bash
./ebuild-bumper.sh -b /usr/portage/category/package/ -o 0.1 -n 0.2
```

### Bump File
The bump file works off 5 variables, all pretty self explanatory. Place 
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

To bump a multiple packages using a bump file
```bash
./ebuild-bumper.sh -f /path/to/bump_file -o 0.1 -n 0.2
```

# Help
For more information see the following options

```bash
Ebuild bumper
Copyright 2016 Obsidian-Studios, Inc.
Distributed under the terms of The GNU Public License v3.0 (GPLv3)

 Global Options:
  -b, --bump                 Bump stand alone package, path to ebuild
  -c, --clean                Clean/remove old version
  -C, --clean-all            Clean/remove all old versions
  -f, --file                 File to source for package specific variables
                             Not used with -b option/overrides
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
