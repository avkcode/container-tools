.PHONY: help shellcheck qemu-user-static debian11 debian11-java-jdk18 debian11-java-jdk18-slim debian11-java-jdk18-maven-slim

.DEFAULT_GOAL := help
.ONESHELL:
.EXPORT_ALL_VARIABLES:

ifndef VERBOSE
.SILENT:
endif

include tools.mk

#------------------------------------------------------------------------------

print-%:
	@echo '$*=$(subst ','\'',$(subst $(newline),\n,$($*)))'

help:
	@echo
	@echo "Usage: make <target>"
	@echo
	@echo " * 'print-%' - print-{VAR} - Print variables"
	@echo
	@echo
	@echo " * 'shellcheck' - Bash scripts linter"
	@echo
	@echo " * 'qemu-user-static' - Register binfmt_misc, qemu-user-static"
	@echo
	@echo " ============================"
	@echo "  ** Debian Linux targets ** "
	@echo " ============================"
	@echo
	@echo "|debian11|"
	@echo "|debian11-java|"
	@echo "|debian11-java-slim|"
	@echo "|debian11-corretto|"
	@echo "|debian11-graal|"
	@echo "|debian11-graal-slim|"
	@echo "|debian11-java-slim-maven|"
	@echo "|debian11-java-slim-gradle|"
	@echo "|debian11-graal-slim-maven|"
	@echo "|debian11-graal-slim-gradle|"

#------------------------------------------------------------------------------
SHELL = /usr/bin/env bash -o pipefail
.SHELLFLAGS = -ec

export SHELL := /bin/bash
export CWD := $(shell pwd)

SRCDIR := $(abspath $(dir $(lastword $(MAKEFILE_LIST))))
BUILDDIR := .

PRINT_HEADER = @echo -e "\n********************[ $@ ]********************\n"

RECIPES = recipes
JAVA_RECIPES = $(RECIPES)/java
SCRIPTS = scripts

DEBIAN_DIR = debian
DEBIAN_BUILD_SCRIPT = $(DEBIAN_DIR)/mkimage.sh
DEBIAN_KEYS_DIRECTORY = $(DEBIAN_DIR)/keys
DEBIAN_KEYRING = $(DEBIAN_KEYS_DIRECTORY)/debian-archive-keyring.gpg

all:debian11 debian11-java debian11-java-slim debian11-graal debian11-graal-slim debian11-corretto debian11-java-slim-maven debian11-java-slim-gradle

debian11:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyrign=$(DEBIAN_KEYRING) \
			--variant=container \
			--release=stable \
			--scripts=$(SCRIPTS)/security-scan.sh

debian11-java:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyrign=$(DEBIAN_KEYRING) \
			--variant=container \
			--release=stable \
			--recipes=$(JAVA_RECIPES)/java.sh \
			--scripts=$(SCRIPTS)/security-scan.sh

debian11-java-slim:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyrign=$(DEBIAN_KEYRING) \
			--variant=container \
			--release=stable \
			--recipes=$(JAVA_RECIPES)/java_slim.sh \
			--scripts=$(SCRIPTS)/security-scan.sh

debian11-graal:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyrign=$(DEBIAN_KEYRING) \
			--variant=container \
			--release=stable \
			--recipes=$(JAVA_RECIPES)/graalvm.sh \
			--scripts=$(SCRIPTS)/security-scan.sh

debian11-graal-slim:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyrign=$(DEBIAN_KEYRING) \
			--variant=container \
			--release=stable \
			--recipes=$(JAVA_RECIPES)/graalvm_slim.sh \
			--scripts=$(SCRIPTS)/security-scan.sh

debian11-corretto:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyrign=$(DEBIAN_KEYRING) \
			--variant=container \
			--release=stable \
			--recipes=$(JAVA_RECIPES)/corretto.sh \
			--scripts=$(SCRIPTS)/security-scan.sh

debian11-java-slim-maven:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyrign=$(DEBIAN_KEYRING) \
			--variant=container \
			--release=stable \
			--recipes=$(JAVA_RECIPES)/java_slim.sh,$(JAVA_RECIPES)/maven.sh \
			--scripts=$(SCRIPTS)/security-scan.sh

debian11-java-slim-gradle:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyrign=$(DEBIAN_KEYRING) \
			--variant=container \
			--release=stable \
			--recipes=$(JAVA_RECIPES)/java_slim.sh,$(JAVA_RECIPES)/gradle.sh \
			--scripts=$(SCRIPTS)/security-scan.sh

debian11-graal-slim-maven:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyrign=$(DEBIAN_KEYRING) \
			--variant=container \
			--release=stable \
			--recipes=$(JAVA_RECIPES)/graalvm_slim.sh,$(JAVA_RECIPES)/maven.sh \
			--scripts=$(SCRIPTS)/security-scan.sh

debian11-graal-slim-gradle:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyrign=$(DEBIAN_KEYRING) \
			--variant=container \
			--release=stable \
			--recipes=$(JAVA_RECIPES)/graalvm_slim.sh,$(JAVA_RECIPES)/gradle.sh \
			--scripts=$(SCRIPTS)/security-scan.sh

