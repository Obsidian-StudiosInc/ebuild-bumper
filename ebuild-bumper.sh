#!/bin/bash
# Copyright 2016 Obsidian-Studios, Inc.
# Author William L. Thomson Jr.
#        wlt@o-sinc.com
#
# Distributed under the terms of The GNU Public License v3.0 (GPLv3)

VERSION="Version 0.2"

help() {
        echo "Usage: ${0} [OPTION...]

${0} -v -c -f <pkg_file> -n <new_version> -o <old_version> [ -r <index> ]

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
"
	[[ $1 ]] && echo Error\: $1
	exit $2
}

version() {
        echo ${VERSION}
	exit 0
}

[[ ! ${1} ]] && help "" 1

# Parse parameters
while :
do
	case "$1" in
		-c | --clean)
			CLEAN="true"
			shift
			;;
		-C | --clean-all)
			CLEAN_ALL="true"
			shift
			;;
		-f | --file)
			[[ -z ${2} ]] && help "Missing package variables file" 1
			source ${2}
			shift 2
			;;
		-n | --new-version)
			[[ -z ${2} ]] && help "Missing new ebuild version" 1
			NPV=${2}
			shift 2
			;;
		-o | --old-version)
			[[ -z ${2} ]] && \
				help "Missing old/current ebuild version" 1
			OPV=${2}
			shift 2
			;;
		-r | --resume)
			[[ -z ${2} ]] && \
				help "Missing array index to resume" 1
			RESUME=${2}
			shift 2
			;;
		-v | --verbose)
			VERBOSE="-v"
			shift
			;;
		-V | --version)
			version
			;;
		--)
			shift
			break
			;;
		-? | --help)
			help "" 0
			;;
		-*)
                        echo "Error: Unknown option: $1 >&2"
			exit 2
                        ;;
		*)
			break
			;;
	esac
done

merge_deps() {
	# Emerge needed deps since using O/oneshot
	local pkg
	for pkg in ${DEPS}; do
		if [[ ! -d /usr/share/${pkg}/ ]]; then
			sudo emerge -qv ${pkg}
			[[ $? -ne 0 ]] && exit 1
		fi
	done
}

bump() {
	# Bump packages, order matters
	local pkg
	for pkg in ${PKGS[@]:${RESUME}}; do
		local my_pn="${BASE}${pkg}"
		local my_p="${my_pn}-${NPV}"

		cd ${REPO}/${CAT}/${my_pn}/
		[[ ${VERBOSE} ]] && pwd

		# if bumped skip
		[[ -e ${my_p}.ebuild ]] && continue

		# if 9999 exists create symlink, copy otherwise
		if [[ -f ${my_pn}-9999.ebuild ]]; then
			ln -s ${VERBOSE} ${my_pn}-9999.ebuild ${my_p}.ebuild \
				|| exit 1
		else
			cp ${VERBOSE} ${my_pn}-${OPV}.ebuild ${my_p}.ebuild \
				|| exit 1
		fi

		ebuild ${my_p}.ebuild digest
		sudo emerge -qvO1 =${my_p}
		[[ $? -ne 0 ]] && exit 1
		if [[ ${CLEAN} ]]; then
			rm -v ${my_pn}-${OPV}.ebuild
			ebuild ${my_p}.ebuild digest
		fi
		git add .
		repoman || exit 1
		repoman commit -m \
			"${CAT}/${my_pn}: Bumped to latest version" \
			|| exit 1
	done
}

clean() {
	# Clean packages, order matters
	local pkg
	local sort_args="-t. -n -k1,1Vr -k2,2nr -k3,3nr -k3.2,3.2d -k4V"
	local RPKGS=( $( echo ${PKGS[@]} | tac -s ' ' ) )
	for pkg in ${RPKGS[@]:${RESUME}}; do
		local my_pn="${BASE}${pkg}"

		cd ${REPO}/${CAT}/${my_pn}/

		# Find all ebuilds, sorted, in array
		local EBUILDS=( $( ls *ebuild | \
			LC_COLLATE=C sort ${sort_args} ) )

		[[ ${#EBUILDS[@]} -le 1 ]] && continue

		local start=1
		if [[ ${EBUILDS[@]} == *"9999"* ]]; then
			[[ ${#EBUILDS[@]} -eq 2 ]] && continue
			let start=2
		fi

		for ebuild in ${EBUILDS[@]:${start}}; do
			git rm ${ebuild}
		done

		ebuild ${EBUILDS[@]:0:1} digest

		repoman || exit 1

		repoman commit -m "${CAT}/${my_pn}: Cleaning old version(s)"
	done
}

[[ ! ${PKGS} ]] && help "Missing packages to bump, package file?" 1
[[ ! ${RESUME} ]] && RESUME=0

if [[ ${CLEAN_ALL} ]]; then
	clean
else
	[[ ! ${NPV} ]] && help "Missing new package version" 1
	[[ ! ${OPV} ]] && help "Missing old/current package version" 1

	merge_deps
	bump
fi

exit 0
