#!/usr/bin/env bash
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
MKFLAG_VIRTUALENV=${WORK_DIR}/virtualenv.flg
if [ "$1" == "-d" ] ; then
	[ -f $MKFLAG_VIRTUALENV ] && \
		highlight "    Removing virtualenv ${PROJECT_NAME}" &&
		pyenv virtualenv-delete -f ${PROJECT_NAME} 2>/dev/null &&\
		rm  $MKFLAG_VIRTUALENV
	rm_if_exists poetry.lock 
	rm_if_exists .python-version 
	rm_if_exists -d .pytest_cache
	rm_if_exists -d $SRC_DIRS/build
	rm_if_exists -d $SRC_DIRS/dist
	rm_if_exists -d dist
	find . -type d -name "__pycache__" -exec rm_if_exists  -d  {} \;
	rm_if_exists -d $WORK_DIR

	exit 0
fi

[ ! -d $WORK_DIR ] && mkdir $WORK_DIR 

if [ ! -f $MKFLAG_VIRTUALENV ] ; then
	pyenv virtualenv $PROJECT_NAME
	[ $? -ne 0 ] && fail "Unable to install virtualenv '$PROJECT_NAME'"
	touch $MKFLAG_VIRTUALENV
fi

if [ ! -f .python-version ] ; then
	echo "    Setting local pyenv to ${PROJECT_NAME}"
	pyenv local ${PROJECT_NAME}
fi

# Following NEEDS to be run in a subshell to work
echo "    Installing dependencies from pyproject.toml"
(
. ~/.pyenv/plugins/pyenv-virtualenv/shims/activate 2>/dev/null && poetry install
)
[ $? -ne 0 ] && fail "Could not install dependencies"
exit 0

