#!/bin/bash
set -e
cd $(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

if ! command -v ansi >/dev/null; then
	alias ansi=$(pwd)/ansi
fi
HR="$(ansi --black --bg-white "##############################################################################")"
MODULE="goenable"
OPTIONS="test1 test2"
MODES="load run"
ef=/tmp/$MODULE.err
of=/tmp/$MODULE.out

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
	done 2>$ef
}

trap killcps EXIT

do_test() {
	cmd="$(cat <<CAT_EOF
#!/usr/bin/env bash
echo Bash \$BASH_VERSION
set +e
make --quiet >/dev/null && env bash --norc --noprofile -i << EOF
source ~/bash-it/themes/powerline/powerline.*bash
  for opt in \$OPTIONS; do
   enable -f ./out/${MODULE}.so $MODULE
    for MODE in \$MODES; do
      $MODULE $MODE \$opt
    done
    enable -d $MODULE
    sleep .2
  done
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
		eval "$cmd" 2>&"${cperr[1]}" >&"${cpout[1]}"
		ec=$?
		if [[ "$ec" != 0 ]]; then
			ansi --red "$cmd FAILED- $ec"
			cat $ef
			exit $ec
		else
			ansi --green "OK!"
		fi
	}
}

killcps() {
	set +e
	while [[ "$(jobs -p)" != "" ]]; do
		jobs -p | tr '\n' ' '
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
}

do_test
