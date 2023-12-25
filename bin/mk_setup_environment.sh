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

if [ "$1" == "-d" ] ; then
	echo "    Removing virtualenv ${PROJECT_NAME}"
	pyenv virtualenv-delete -f ${PROJECT_NAME} 2>/dev/null
	rm poetry.lock
	echo "    Removing local pyenv version"
	rm .python-version 2>/dev/null
	echo "    Removing caches and flags"
	find . -type d -name "__pycache__" -exec rm -rf {} \;
	rm -rf $WORK_DIR  2>/dev/null
	rm -rf dist 2>/dev/null

	exit 0
fi

[ ! -d $WORK_DIR ] && mkdir $WORK_DIR 
MKFLAG_VIRTUALENV=${WORK_DIR}/virtualenv.flg

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

