#!/usr/bin/env bash
: << DOCXX
#------------------------------------------------------------------------------
#          Name:    mk_brew_publish.sh
#   Description:    Publishes the package from github to my homebrew tap
#    Parameters:    None
#
#------------------------------------------------------------------------------
DOCXX

. ${0%/*}/.bash.common

[ $WORK_DIR ] || fail "Expected to find WORK_DIR from MAKE environment"
build_homebrew=$(python -c 'import toml;print(toml.load("pyproject.toml")["tool"]["homebrew"]["build"])' 2>/dev/null)
case "$build_homebrew" in
	"") echo "*** Warning - tool.homebrew.build not found in pyproject.toml - building anyway ***";;
	"False") 	echo "tool.homebrew.build = False  # *** Skipping build ***"
				exit 0;;
	"True")		:;;
	*)	echo "*** Error - tool.homebrew.build=$build_homebrew should be True or False ***"
		exit 1;;
esac

# Ask to publish unless on main branch
git_branch=$(git branch 2> /dev/null | sed -n -e 's/^\* \(.*\)/\1/p')
[ "$git_branch" == "main" ] ||\
	yn "Your git branch is '$git_branch' - are you sure you want to publish?" || \
		fail "Not publishing this"

project=$(poetry version|cut -d" " -f1)
version=$(poetry version|cut -d" " -f2)
config=${project}.rb
template=${WORK_DIR}/${project}.tmpl

url="https://github.com/dmlane/${project}/archive/refs/tags/${version}.tar.gz"

function get_url {
	curl -sL $url
	[ $? -ne 0 ] && fail "Unable to fetch $url"
}

sha=$(get_url|sha256sum|cut -d" " -f1)
sed -e "s?#URL#?$url?" -e "s/#SHA256#/$sha/" $template >../homebrew-tap/Formula/$config
[ $? -ne 0 ] && fail "sed failed"

cd ../homebrew-tap/Formula
git add $config || exit 1
git commit -m "Updated $config to release $version" || exit 1
git push || exit 1
highlight "^${project} version ${version} deployed${NC} ++++++++++^"
