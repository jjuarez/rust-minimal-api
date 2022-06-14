#!/usr/bin/env make

.DEFAULT_GOAL             := help
.DEFAULT_SHELL            := /bin/bash

DOCKER_BUILDKIT   ?= 1
BUILDKIT_PROGRESS ?= auto

VSCAN_HIGH_EXIT_CODE     ?= 0
VSCAN_CRITICAL_EXIT_CODE ?= 1

DOCKER_REGISTRY           := docker.io
DOCKER_REGISTRY_NAMESPACE := jjuarez
DOCKER_IMAGE_NAME         := rust-minimal-api
DOCKER_IMAGE              := $(DOCKER_REGISTRY)/$(DOCKER_REGISTRY_NAMESPACE)/$(DOCKER_IMAGE_NAME)
DOCKER_USERNAME           ?= jjuarez
DOCKER_FILE               ?= Dockerfile

HADOLINT_DOCKER_IMAGE        := hadolint/hadolint:v2.10.0
SHELLCHECK_DOCKER_IMAGE      := koalaman/shellcheck:stable
OPENPOLICYAGENT_DOCKER_IMAGE := openpolicyagent/conftest:v0.32.1
TRIVY_DOCKER_IMAGE           := aquasec/trivy:0.28.1
TRIVY_DEBUG                  ?= false
TRIVY_CACHE_BACKEND          ?= fs
TRIVY_CACHE_DIR              ?= $(HOME)/.cache/trivy

PROJECT_CHANGESET := $(shell git rev-parse --verify HEAD 2>/dev/null)


define assert-set
	@$(if $($1),,$(error $(1) environment variable is not defined))
endef

define assert-file
	@$(if $(wildcard $($1) 2>/dev/null),,$(error $1 command not found))
endef

define assert-command
	@$(if $(shell command -v $1 2>/dev/null),,$(error $1 command not found))
endef


.PHONY: help
help: ## Shows this help screen
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make <target>\n\nTargets:\n"} /^[a-zA-Z//_-]+:.*?##/ { printf " %-25s %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

.PHONY: docker/lint
docker/lint: ## Makes a lint over the Dockerfile
	@docker run --rm -i $(HADOLINT_DOCKER_IMAGE) < $(DOCKER_FILE)

.PHONY: docker/sast
docker/sast: ## Makes the SAST tests
	@docker run --rm -v$(PWD):/project $(OPENPOLICYAGENT_DOCKER_IMAGE) test --policy dockerfile-security.rego $(DOCKER_FILE)

.PHONY: docker/login
docker/login:
	$(call assert-set,DOCKER_USERNAME)
	$(call assert-set,DOCKER_PASSWORD)
	@echo $(DOCKER_PASSWORD)|docker login --username $(DOCKER_USERNAME) --password-stdin $(DOCKER_REGISTRY)

.PHONY: docker/build
docker/build: docker/login ## Makes the Docker build and takes care of the remote cache
	@docker image build \
    --cache-from $(DOCKER_IMAGE):latest \
    --tag $(DOCKER_IMAGE):$(PROJECT_CHANGESET) \
    --file $(DOCKER_FILE) \
    .
	@docker image tag $(DOCKER_IMAGE):$(PROJECT_CHANGESET) $(DOCKER_IMAGE):latest
	@docker image push $(DOCKER_IMAGE):latest

.PHONY: docker/pull
docker/pull: docker/login
	@docker image pull $(DOCKER_IMAGE):latest

.PHONY: docker/vscan
docker/vscan: docker/pull ## Makes a vulnerability scan over the Docker image
	@docker run --name trivy --rm -e GITHUB_TOKEN -e TRIVY_DEBUG -e TRIVY_CACHE_BACKEND -e TRIVY_CACHE_DIR=/root/.cache/trivy \
    --volume /var/run/docker.sock:/var/run/docker.sock \
    --volume $(HOME)/.cache/trivy:/root/.cache/trivy\
    -it $(TRIVY_DOCKER_IMAGE) image --exit-code $(VSCAN_HIGH_EXIT_CODE) --severity LOW,MEDIUM,HIGH --no-progress $(DOCKER_IMAGE):latest
	@docker run --name trivy --rm -e GITHUB_TOKEN -e TRIVY_DEBUG -e TRIVY_CACHE_BACKEND -e TRIVY_CACHE_DIR=/root/.cache/trivy \
    --volume /var/run/docker.sock:/var/run/docker.sock \
    --volume $(HOME)/.cache/trivy:/root/.cache/trivy\
	  -it $(TRIVY_DOCKER_IMAGE) image --exit-code $(VSCAN_CRITICAL_EXIT_CODE) --severity CRITICAL --no-progress $(DOCKER_IMAGE):latest

.PHONY: docker/release
docker/release: docker/build ## Docker image relase push to the registry
	@docker image push $(DOCKER_IMAGE):latest
	@docker image push $(DOCKER_IMAGE):$(PROJECT_CHANGESET)
ifdef PROJECT_VERSION
	@docker image tag $(DOCKER_IMAGE):$(PROJECT_CHANGESET) $(DOCKER_IMAGE):$(PROJECT_VERSION)
	@docker image push $(DOCKER_IMAGE):$(PROJECT_VERSION)
endif
