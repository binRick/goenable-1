#!/usr/bin/env bash
cd $(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
set -e
default_watch_file="-e go,sh,j2"
watch_file="${1:-$default_watch_file}"
shift || true
cmd="./${@:-./test.sh}"
cmd="reap nodemon -w templates -i src -i out -i tmp -w .envrc.sh --signal SIGINT -w Makefile -w dev.sh -w test.sh --delay .1 $watch_file -x sh -- -c './${cmd}||true'"
eval "$cmd"
