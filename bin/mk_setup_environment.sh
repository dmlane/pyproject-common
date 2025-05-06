#!/usr/bin/env bash
# shellcheck disable=SC2086,SC2156
: << DOCXX
#------------------------------------------------------------------------------
#          Name:    mk_setup_environment.sh
#   Description:    Setup environment in this directory
#    Parameters:    [-d] - deletes the environment
#
#------------------------------------------------------------------------------
DOCXX

. ${0%/*}/.bash.common

# Fail if any of these commands are missing (bumpver not needed by this script
#                                            but needed by the project)
require_commands poetry pyenv bumpver
[ $WORK_DIR ] || fail "Expected to find WORK_DIR from MAKE environment"
[ $SRC_DIRS ] || fail "Expected to find SRC_DIRS from MAKE environment"

function rm_if_exists {
	if [ "$1" == "-d" ] ; then
		[ -d "$2" ] || return
		highlight "    Removing directory ^$2^"
		rm -rf "$2"
		return
	fi
	[ -e "$1" ] || return
	highlight "    Removing ^$1^"
	rm "$1"
	return
}
export -f rm_if_exists

MKFLAG_VIRTUALENV=${WORK_DIR}/virtualenv.flg
if [ "$1" == "-d" ] ; then
	[ -d /Users/dave/.pyenv/versions/${PROJECT_NAME} ] && \
		highlight "    Removing virtualenv ${PROJECT_NAME}" &&
		pyenv virtualenv-delete -f ${PROJECT_NAME} 2>/dev/null &&\
		rm  $MKFLAG_VIRTUALENV 2>/dev/null
	rm_if_exists .python-version 
	rm_if_exists -d .pytest_cache
	rm_if_exists -d $SRC_DIRS/build
	rm_if_exists -d $SRC_DIRS/dist
	rm_if_exists -d dist
	find . -type d -name "__pycache__" -exec bash -c 'rm_if_exists -d "{}"' \;
	find $WORK_DIR -type f ! -name ".versions" -mindepth 1 -maxdepth 1 -exec bash -c 'rm_if_exists "{}"' \;

	exit 0
fi
rm_if_exists poetry.lock
[ ! -d $WORK_DIR ] && mkdir -p $WORK_DIR 

if [ ! -f $MKFLAG_VIRTUALENV ] ; then
	if ! pyenv virtualenv $PROJECT_NAME ; then
		fail "Unable to install virtualenv '$PROJECT_NAME'"
	fi
	touch $MKFLAG_VIRTUALENV
fi

if [ ! -f .python-version ] ; then
	echo "    Setting local pyenv to ${PROJECT_NAME}"
	pyenv local ${PROJECT_NAME}
fi

# Following NEEDS to be run in a subshell to work
echo "    Installing dependencies from pyproject.toml"
(
eval "$(pyenv init -)"
eval "$(pyenv virtualenv-init -)"
if pyenv activate ${PROJECT_NAME} ; then
	poetry install
	pyenv rehash
fi
) || fail "Could not install dependencies"
exit 0

