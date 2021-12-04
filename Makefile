GO111MODULE := on
CGO_ENABLED := 1
export
TARGETS := darwin/amd64,linux/amd64
GO_VERSION := 1.17.2
BASH_VERSION := 5.1.8
SHELL := /usr/bin/env bash
TEMPLATES_DIR := ./templates
SRC_DIR := ./

.PHONY: all
all: module

.PHONY: dist
dist: out
	cd /tmp; GO111MODULE=auto go get -u github.com/johnstarich/xgo  # avoid updating go.mod files
	xgo \
		--buildmode=c-shared \
		--deps="http://ftpmirror.gnu.org/bash/bash-${BASH_VERSION}.tar.gz" \
		--depsargs="--disable-nls" \
		--dest=out \
		--go="${GO_VERSION}" \
		--image="johnstarich/xgo:1.11-nano" \
		--targets="${TARGETS}" \
		.
	set -e; \
		if [[ -d out/github.com ]]; then \
			mv -fv out/github.com/johnstarich/* out/; \
			rm -rf out/github.com; \
		fi
	go run ./cmd/rename_binaries.go ./out

out:
	mkdir out

.PHONY: clean
clean:
	rm -rf out

.PHONY: module
module: out
	[[ -d "${SRC_DIR}" ]] || mkdir -p "${SRC_DIR}"
	rsync ${TEMPLATES_DIR}/*.j2 ${TMP_DIR}/.
	replace '[[MODULE]]' '{{MODULE}}' -- ${TMP_DIR}/*.j2
	command jinja -D MODULE ${MODULE} ${TMP_DIR}/bash_structs.go.j2 -o ${SRC_DIR}/bash_structs.go
	command jinja -D MODULE ${MODULE} ${TMP_DIR}/bash.go.j2 -o ${SRC_DIR}/bash.go
	command jinja -D MODULE ${MODULE} ${TMP_DIR}/hooks.go.j2 -o ${SRC_DIR}/hooks.go
	env CGO_ENABLED=${CGO_ENABLED} go build -o out/${MODULE}.so -buildmode=c-shared ${SRC_DIR}/.
