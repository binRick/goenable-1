GO111MODULE := on
CGO_ENABLED := 1
TMP_DIR := ./tmp
SRC_DIR := ./src
OUT_DIR := ./out
export
TARGETS := darwin/amd64,linux/amd64
GO_VERSION := 1.17.2
BASH_VERSION := 5.1.8
SHELL := /usr/bin/env bash
TEMPLATES_DIR := ./templates

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
	mkdir out src tmp

.PHONY: clean
clean:
	rm -rf out src tmp

.PHONY: module
module: out
	[[ -d "${TMP_DIR}" ]] || mkdir -p "${TMP_DIR}"
	[[ -d "${SRC_DIR}" ]] || mkdir -p "${SRC_DIR}"
	[[ -d "${OUT_DIR}" ]] || mkdir -p "${OUT_DIR}"
	rsync -L ${TEMPLATES_DIR}/*.go ${TMP_DIR}/.
	rsync -ar cutils ${SRC_DIR}/.
	rsync go.mod  ${SRC_DIR}/.
	rsync go.sum  ${SRC_DIR}/.
	replace '__MODULE__' '{{MODULE}}' -- ${TMP_DIR}/*.go
	command jinja -D MODULE ${MODULE} ${TMP_DIR}/bash_structs.go -o ${SRC_DIR}/bash_structs.go
	command jinja -D MODULE ${MODULE} ${TMP_DIR}/bash.go -o ${SRC_DIR}/bash.go
	command jinja -D MODULE ${MODULE} ${TMP_DIR}/hooks.go -o ${SRC_DIR}/hooks.go
	command jinja -D MODULE ${MODULE} ${TMP_DIR}/main.go -o ${SRC_DIR}/main.go
	cd ${SRC_DIR} && env CGO_ENABLED=${CGO_ENABLED} go build -o ../out/${MODULE}.so -buildmode=c-shared .


