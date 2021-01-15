
BACKEND?=docker
CONCURRENCY?=1
CI_ARGS?=
PACKAGES?=

# Abs path only. It gets copied in chroot in pre-seed stages
export LUET?=/usr/bin/luet
export ROOT_DIR:=$(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
DESTINATION?=$(ROOT_DIR)/build
COMPRESSION?=gzip
CLEAN?=false
export TREE?=$(ROOT_DIR)/packages
REPO_CACHE?=quay.io/mocaccinocache/micro-amd64-cache
export REPO_CACHE
BUILD_ARGS?=--pull --no-spinner --config $(ROOT_DIR)/conf/luet.yaml
SUDO?=
VALIDATE_OPTIONS?=-s
ARCH?=amd64

ifneq ($(strip $(REPO_CACHE)),)
	BUILD_ARGS+=--image-repository $(REPO_CACHE)
endif

.PHONY: all
all: deps build

.PHONY: deps
deps:
	@echo "Installing luet"
	go get -u github.com/mudler/luet

.PHONY: clean
clean:
	$(SUDO) rm -rf build/ *.tar *.metadata.yaml

.PHONY: build
build: clean
	mkdir -p $(DESTINATION)
	$(SUDO) $(LUET) build $(BUILD_ARGS) --values arches/$(ARCH)/values.yaml --tree=$(TREE) $(PACKAGES) --destination $(DESTINATION) --backend $(BACKEND) --concurrency $(CONCURRENCY) --compression $(COMPRESSION)

.PHONY: build-all
build-all: clean
	mkdir -p $(DESTINATION)
	$(SUDO) $(LUET) build $(BUILD_ARGS) --values arches/$(ARCH)/values.yaml --tree=$(TREE) --full --destination $(DESTINATION) --backend $(BACKEND) --concurrency $(CONCURRENCY) --compression $(COMPRESSION)

.PHONY: rebuild
rebuild:
	$(SUDO) $(LUET) build $(BUILD_ARGS) --values arches/$(ARCH)/values.yaml --tree=$(TREE) $(PACKAGES) --destination $(DESTINATION) --backend $(BACKEND) --concurrency $(CONCURRENCY) --compression $(COMPRESSION)

.PHONY: rebuild-all
rebuild-all:
	$(SUDO) $(LUET) build $(BUILD_ARGS) --values arches/$(ARCH)/values.yaml --tree=$(TREE) --full --destination $(DESTINATION) --backend $(BACKEND) --concurrency $(CONCURRENCY) --compression $(COMPRESSION)

.PHONY: create-repo
create-repo:
	$(SUDO) $(LUET) create-repo --tree "$(TREE)" \
    --output $(DESTINATION) \
    --packages $(DESTINATION) \
    --name "mocaccino-micro" \
    --descr "Mocaccino Micro $(ARCH)" \
    --urls "http://localhost:8000" \
    --tree-compression gzip \
    --tree-filename tree.tar \
    --meta-compression gzip \
    --type http

.PHONY: serve-repo
serve-repo:
	LUET_NOLOCK=true $(LUET) serve-repo --port 8000 --dir $(DESTINATION)

auto-bump:
	TREE_DIR=$(ROOT_DIR) $(LUET) autobump-github

autobump: auto-bump

validate:
	$(LUET)  tree validate --tree $(TREE) $(VALIDATE_OPTIONS)

