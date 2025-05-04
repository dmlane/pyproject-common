#!/usr/bin/env bash
#
# pre-commit.sh
# =============
#
#	Run format and lint checks against python files and fails
#   if any problems detected. This will stop git from committing.
#

YELLOW='\033[1;33m'
RED='\033[1;31m'
GREEN='\033[1;32m'
NC='\033[1;0m'
function run_check {
	local log=/tmp/run_check.$1.stderr
	printf "${GREEN}Running ${YELLOW}%9s${GREEN} against new python files ..... " $1
	$* $py_files  >$log 2>&1
	if [ $? -eq 0 ] ; then
		rm $log
		echo -e "${YELLOW} succeeded${NC}"
		return
	fi
	echo -e "${RED} 💥💥failed💥💥${NC}"
	((err++))
}
OIFS="$IFS"
IFS=$'\n'
err=0
py_files=$(git diff --cached --name-only --diff-filter=ACM |grep '.py$')
test -z "$py_files" && exit 0

echo -e "${YELLOW}Checking the following python files for problems:${NC}"
for fn in $py_files
do
	echo -e "    ${GREEN}${fn}${NC}"
done

run_check black --check --diff
run_check isort --check-only 
run_check pylint -rn -sn 

if [ $err -gt 0 ] ; then
	echo -e "${RED}Aborting git commit -see logs in /tmp ??????????${NC}"
	exit 1
fi
