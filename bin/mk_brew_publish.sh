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

# Ask to publish unless on main branch
git_branch=$(git branch 2> /dev/null | sed -n -e 's/^\* \(.*\)/\1/p')
yn "Your git branch is '$git_branch' - are you sure you want to publish?" || \
	fail "Not publishing this"

project=$(poetry version|cut -d" " -f1)
version=$(poetry version|cut -d" " -f2)
config=${project}.rb
template=${project}.tmpl

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
