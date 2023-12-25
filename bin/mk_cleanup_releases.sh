#!/usr/bin/env bash
: << DOCXX
#------------------------------------------------------------------------------
#          Name:    mk_cleanup.sh
#   Description:    Cleanup fury and github tagged versions. This should only
#                   be called during a Release run as we clearout all test
#                   tags and outdated release tags.
#    Parameters:    None
#
#------------------------------------------------------------------------------
DOCXX

. ${0%/*}/.bash.common

MONTHS_TO_KEEP=6
MIN_VERSIONS=4
SECS_CUTOFF=$(date -d "${MONTHS_TO_KEEP} months ago" +"%s")

IFS=$'\n'

# Process GemFury to remove old versions
[ ! $PROJECT_NAME ] && fail "Expected make to set PROJECT_NAME"
for rec in $(fury versions ${PROJECT_NAME}|sed -n '/^version/,${/^version/!p;}'|sort -k3r)
do
	release=$(awk '{print $1}'<<<$rec)
	dt=$(awk '{print $3,$4}'<<<$rec)
	if [[ $release == *rc0 ]] ; then
		fury yank $PROJECT_NAME -v $release
		continue
	fi
	(( MIN_VERSIONS-- ))
	[ $MIN_VERSIONS -ge 0 ] && continue
	release_date=$(date -d "$dt" +"%s")
	set -xv
	[ $release_date -lt $SECS_CUTOFF ] && fury yank $PROJECT_NAME -v $release
	set +xv
done

# Updated list
fury_versions=()
for version in $(fury versions ${PROJECT_NAME}|sed -n '/^version/,${/^version/!p;}'|cut -d " " -f1|sort -k1r )
do
	fury_versions+=("$version")
done

# Process tags in github
for version in $(git ls-remote --tags --refs origin|sed -e 's?^.*refs/tags/\(.*\)$?\1?'|sort)
do
	if [[ ${fury_versions[@]} =~ $version ]] ; then
		highlight "Keeping GitHub tag ^$version$^"
	else
		echo -e "${DARK_GREEN}Removing GitHub tag ${RED}$version${NC}"
		git push origin :refs/tags/${version}
		git tag -d $version
	fi
done

