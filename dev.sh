#!/usr/bin/env bash
cd $(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
set -e
default_watch_file=". -e go,sh,j2"
watch_file="${1:-$default_watch_file}"
shift || true
cmd="./${@:-./test.sh}"
#cmd="nodemon -I --delay .4 -w pkg -w example -e sh,go,yaml,yml -x sh -- -c '$cmd||true'"
cmd="reap nodemon -i bash.go -i hooks.go --signal SIGINT -w Makefile -i bash_structs.go -I --delay .1 -w $watch_file -x sh -- -c './${cmd}||true'"
eval "$cmd"
