#!/bin/bash
# Copyright 2016-2018 Obsidian-Studios, Inc.
# Author William L. Thomson Jr.
#        wlt@o-sinc.com
#
# Distributed under the terms of The GNU Public License v3.0 (GPLv3)

VERSION="Version 0.7"

help() {
	local me
	me="${0##*/}"
        echo "Ebuild bumper - Version bump ebuild(s)
Usage:
    ${me} -n <new_PV> -o <old_PV> <bump_file or pkg_dir>
    ${me} -u <old_PV> <bump_file or pkg_dir>
    ${me} -C -o <old_PV> <bump_file or pkg_dir>
    ${me} -C <bump_file or pkg_dir>

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

Copyright 2016-2018 Obsidian-Studios, Inc.
Distributed under the terms of The GNU Public License v3.0 (GPLv3)
"
	[[ $1 ]] && echo "Error: $1"
	exit "$2"
}

version() {
        echo "${VERSION}"
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
		-d | --do-not)
			NO_MERGE="true"
			shift
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
		-u | --uninstall)
			REMOVE="true"
			shift
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
			if [[ -f "${1}" ]]; then
				# shellcheck disable=SC1090
				. "${1}"
				shift
			elif [[ -d "${1}" ]]; then
				PKGS="$( basename "${1}" )"
				case "${1}" in
					*/)
						CAT="$( basename "${1%*/*/}" )"
						REPO="$( dirname "${1%*/*/}" )"
						;;
					*)
						CAT="$( basename "${1%*/*}" )"
						REPO="$( dirname "${1%*/*}" )"
						;;
				esac
				shift
			else
				break
			fi
			;;
	esac
done

merge_deps() {
	# Emerge needed deps since using O/oneshot
	local pkg
	for pkg in ${DEPS}; do
		if [[ ! -d /usr/share/${pkg}/ ]]; then
			sudo emerge -qv "${pkg}" || exit 1
		fi
	done
}

bump() {
	# Bump packages, order matters
	local i

	PKGS=( "${PKGS[@]:${RESUME}}" )
	# shellcheck disable=SC2153
	for i in "${!PKGS[@]}"; do
		local my_cat my_pn my_p pkg

		pkg="${PKGS[${i}]}"
		my_cat="${CAT}"
		my_pn="${BASE}${pkg#*/}"
		my_p="${my_pn}-${NPV}"

		[[ ! "${my_cat}" ]] && my_cat="${pkg%/*}"

		cd "${REPO}/${my_cat}/${my_pn}/" || exit 1
		[[ ${VERBOSE} ]] && pwd

		# if bumped skip
		[[ -e ${my_p}.ebuild ]] && continue

		echo "Bumping ${i} of ${#PKGS[@]} packages"

		# if 9999 exists create symlink, copy otherwise
		if [[ -f ${my_pn}-9999.ebuild ]] && [[  -L "${my_pn}-${OPV}.ebuild" ]]; then
			ln -s ${VERBOSE} "${my_pn}-9999.ebuild" "${my_p}.ebuild" \
				|| exit 1
		else
			cp ${VERBOSE} "${my_pn}-${OPV}.ebuild" "${my_p}.ebuild" \
				|| exit 1
		fi

		ebuild "${my_p}.ebuild" digest
		if [[ ! ${NO_MERGE} ]]; then
			sudo emerge -qvk1 ="${my_cat}/${my_p}" || exit 1
		fi
		if [[ ${CLEAN} ]]; then
			rm -v "${my_pn}-${OPV}.ebuild"
			ebuild "${my_p}.ebuild" digest
		fi
		git add .
		repoman || exit 1
		repoman commit -m \
			"${my_cat}/${my_pn}: Bump ${OPV} -> ${NPV}" \
			|| exit 1
		# ensure repoman did not miss files in commit
		git add .
		git commit --amend --no-edit
	done
}

clean() {
	# Clean packages, order matters
	local pkg
	local sort_args="-t. -n -k1,1Vr -k2,2nr -k3,3nr -k3.2,3.2d -k3.3d,3Vr -k4Vr"
	# shellcheck disable=SC2207
	local RPKGS=( $( echo "${PKGS[@]}" | tac -s ' ' ) )
	for pkg in "${RPKGS[@]:${RESUME}}"; do
		local my_cat my_pn
		my_cat="${CAT}"
		my_pn="${BASE}${pkg#*/}"

		[[ ! "${my_cat}" ]] && my_cat="${pkg%/*}"

		cd "${REPO}/${my_cat}/${my_pn}/" || exit 1

		# Find all ebuilds, sorted, in array
		# shellcheck disable=SC2086,SC2207
		local EBUILDS=( $( find -- *ebuild | \
			LC_COLLATE=C sort ${sort_args} ) )

		[[ ${#EBUILDS[@]} -le 1 ]] && continue

		local e start=1
		for e in "${EBUILDS[@]}"; do
			if [[ "${e}" == *"9999"* ]]; then
				[[ ${#EBUILDS[@]} -eq 2 ]] && continue
				(( start=2 ))
			fi
		done

		# Remove single version if specified otherwise clean all
		# Needs to be modified for stable and ~arch cleaning
		if [[ ${OPV} ]]; then
			[[ ! -f "${my_pn}-${OPV}.ebuild" ]] && continue
			git rm "${my_pn}-${OPV}.ebuild"
		else
			for ebuild in "${EBUILDS[@]:${start}}"; do
				git rm "${ebuild}"
			done
		fi

		ebuild "${EBUILDS[@]:0:1}" digest

		repoman || exit 1

		repoman commit -m "${my_cat}/${my_pn}: Cleaning old version(s)"
	done
}

remove() {
	local RPKGS pkg
	# shellcheck disable=SC2207
	RPKGS=( $( echo "${PKGS[@]}" | tac -s ' ' ) )
	for pkg in "${RPKGS[@]}"; do
		local my_cat="${CAT}"
		[[ ! "${my_cat}" ]] && my_cat="${pkg%/*}"
		sudo emerge -qC "${my_cat}/${BASE}${pkg#*/}"
	done
}

[[ ! ${PKGS[0]} ]] && help "Missing packages to bump, package file?" 1
[[ ! ${RESUME} ]] && RESUME=0

# Remove packages before bump
if [[ ${REMOVE} ]]; then
	remove
	# if not bumping, exit
	[[ ! ${OPV} ]] && exit 0
fi

if [[ ${CLEAN_ALL} ]]; then
	clean
else
	[[ ! ${NPV} ]] && help "Missing new package version" 1
	[[ ! ${OPV} ]] && help "Missing old/current package version" 1

	merge_deps
	bump
fi

exit 0
