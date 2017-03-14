# ebuild-bumper.sh
[![License](https://img.shields.io/badge/license-GPLv3-9977bb.svg?style=plastic)](https://github.com/Obsidian-StudiosInc/ebuild-bumper/blob/master/LICENSE)
[![Build Status](https://img.shields.io/travis/Obsidian-StudiosInc/ebuild-bumper/master.svg?colorA=9977bb&style=plastic)](https://travis-ci.org/Obsidian-StudiosInc/ebuild-bumper)
[![Build Status](https://img.shields.io/shippable/5840e5d7e2ab4d0f0058b4b3/master.svg?colorA=9977bb&style=plastic)](https://app.shippable.com/projects/5840e5d7e2ab4d0f0058b4b3/)

A bash script for version bumping an individual ebuild or groups of 
ebuilds with the same version. The script can also clean out older 
versions of the same group ebuilds, or single ebuild version. It can 
clean as it goes, but that is only safe for individual packages. If 
cleaning as part of a group of packages being bumped, it will break the 
dep graph. Which will cause the script to exit when repoman fails.

## Usage
There is two ways to use the script, directly on a single package, or 
using a bump file that provides the necessary variables for multiple 
packages.

### Single package
To bump a single package
```bash
./ebuild-bumper.sh -o 0.1 -n 0.2 /usr/portage/category/package/
```

To clean a single package
```bash
# All old except latest and 9999 if exists
./ebuild-bumper.sh -C /usr/portage/category/package/

# Single version
./ebuild-bumper.sh -c -o 0.1 /usr/portage/category/package/

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

To bump multiple packages using a bump file
```bash
./ebuild-bumper.sh -o 0.1 -n 0.2 /path/to/bump_file
```

To clean multiple packages using a bump file 
```bash
# All old except latest and 9999 if exists
./ebuild-bumper.sh -C /path/to/bump_file

# Single version
./ebuild-bumper.sh -c -o 0.1 /path/to/bump_file

```

# Help
For more information see the following options

```bash
Ebuild bumper - Version bump ebuild(s)
Usage:
    ebuild-bumper.sh -n <new_PV> -o <old_PV> <bump_file or pkg_dir>
    ebuild-bumper.sh -u <old_PV> <bump_file or pkg_dir>
    ebuild-bumper.sh -C -o <old_PV> <bump_file or pkg_dir>
    ebuild-bumper.sh -C <bump_file or pkg_dir>

 Global Options:
  -c, --clean                Clean/remove old version
  -C, --clean-all            Clean/remove all old versions
  -d, --do-not               Do not merge, just bump and commit, no install
  -n, --new-version          New package version string, numeric or
                             alpha/numeric
  -o, --old-version          Old/current package version string, numeric or
                             alpha/numeric
  -r, --resume               Resume at array index, numeric only!
  -u, --uninstall            Uninstall package(s), useful before bumps
  -v, --verbose              Enable verbose commands

 GNU Options:

  -?, --help                 Give this help list
      --usage                Give a short usage message
  -V, --version              Print program version

Copyright 2016-2017 Obsidian-Studios, Inc.
Distributed under the terms of The GNU Public License v3.0 (GPLv3)
```
