#!/usr/bin/env bash
: << DOCXX
#------------------------------------------------------------------------------
#          Name:    mk_tmpl_includes.sh
#   Description:    Regenerates the includes part of the brew tmpl file
#    Parameters:    None
#
#------------------------------------------------------------------------------
DOCXX

. ${0%/*}/.bash.common

# Fail if any of these commands are missing (bumpver not needed by this script
#                                            but needed by the project)
require_commands gsed
[ $PROJECT_NAME ] || fail "Expected to find PROJECT_NAME from MAKE environment"
[ $WORK_DIR ] || fail "Expected to find WORK_DIR from MAKE environment"
[ $HELPER ] || fail "Expected to find HELPER from MAKE environment"

WF=$(mktemp -d)
function on_exit {
    rm -rf ${WF} 2>/dev/null
    exit
}
[ $NO_CLEANUP ] || trap on_exit 0 1 2 15
POETRY_PACKAGES=${WF}/poetry.packages
INCLUDE_FILE=${WF}/include
TEMP_OUTPUT=${WORK_DIR}/${PROJECT_NAME}.tmpl.new
highlight "Getting a list of packages from Poetry"
poetry show --only main >${POETRY_PACKAGES}

highlight "Fetching python resources for ^$PROJECT_NAME^"
${HELPER}/get_pypi_info.py ${POETRY_PACKAGES} >${INCLUDE_FILE} ||\
	fail "'${HELPER}/get_pypi_info.py ${WF}/poetry.package' returned error"

gsed "/#---START-RESOURCES---/,/#---END-RESOURCES---/!b;//!d;/#---START-RESOURCES---/r ${INCLUDE_FILE}" ${PROJECT_NAME}.tmpl >${TEMP_OUTPUT} ||\
	fail "gsed had a problem"
mv -f ${TEMP_OUTPUT} ${WORK_DIR}/${PROJECT_NAME}.tmpl

