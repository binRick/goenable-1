#!/usr/bin/bash
set -e
cd $(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
[[ -f ./.envrc ]] && source ./.envrc
if ! command -v ansi >/dev/null; then alias ansi=$(pwd)/ansi; fi

HR="$(ansi --black --bg-white "##############################################################################")"
MODULE="${MODULE:-goenable}"
OPTIONS="test1 test2"
MODES="load run"
ef=/.$MODULE-test.err
of=/.$MODULE-test.out
TEST_BASH=/usr/bin/bash
TEST_BASH=/opt/bash-5.1/bin/bash

coproc cpout {
	while :; do
		read -r input
		ansi >&2 --green --bg-black --bold "$(ansi --underline --italic "|OUT>")  ${input}"
	done
}

coproc cperr {
	while :; do
		read -r input
		ansi >&2 --red --bg-black --bold "|ERR>  ${input}"
	done
	# 2>$ef
}

trap killcps EXIT

do_test() {
	cmd="$(
		cat <<CAT_EOF
#!${TEST_BASH}
echo Bash \$BASH_VERSION
set +e
make --quiet >/dev/null && env bash --norc --noprofile -i << EOF
#source ~/bash-it/themes/powerline/powerline.*bash
 enable -f ./out/${MODULE}.so $MODULE
 $MODULE load arg1
 enable -d $MODULE
sleep .9
EOF
CAT_EOF
	)"

	echo -e "$HR"
	while read -r l; do
		echo >&2 -e "$(ansi --black --bg-white --bold ">>")  $(ansi --yellow --bg-black --italic "$l")"
	done < <(echo -e "$cmd")
	echo -e "$HR"

	{
		set +e
		cf=$(mktemp)
		echo -e "$cmd" >$cf
		chmod +x $cf
		eval $cf 2>&"${cperr[1]}" >&"${cpout[1]}"
		ec=$?
		if [[ "$ec" != 0 ]]; then
			ansi --red "$cmd - Test Failed - Exited $ec"
			cat $ef
			exit $ec
		else
			ansi --green "Test Finished OK!"
		fi
	}
}

killcps() {
	set +e
	while [[ "$(jobs -p)" != "" ]]; do
		jobs -p >/dev/null && {
			echo -n "Killing Jobs: "
			ansi --bg-black --magenta --bold "$(jobs -p | tr '\n' ' ')"
		}
		echo
		{
			kill %1
			kill %2
			sleep .1
			kill -9 %1
			kill -9 %2
		} 2>/dev/null
		wait
		sleep .1
		jobs -p
		sleep .5
	done
	sleep .1
}

do_test
