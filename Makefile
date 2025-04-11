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
	@echo " * 'sign-tar-files' - Target to sign .tar files in */dist using Cosign"
	@echo
	@echo " ============================"
	@echo "  ** Debian Linux targets ** "
	@echo " ============================"
	@echo
	@echo "|all|"
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
JULIA_RECIPES = $(RECIPES)/julia
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
			--keyring=$(DEBIAN_KEYRING) \
			--variant=container \
			--release=stable \
			--scripts=$(SCRIPTS)/security-scan.sh

debian11-java:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyring=$(DEBIAN_KEYRING) \
			--variant=container \
			--release=stable \
			--recipes=$(JAVA_RECIPES)/java.sh \
			--scripts=$(SCRIPTS)/security-scan.sh

debian11-java-slim:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyring=$(DEBIAN_KEYRING) \
			--variant=container \
			--release=stable \
			--recipes=$(JAVA_RECIPES)/java_slim.sh \
			--scripts=$(SCRIPTS)/security-scan.sh

debian11-graal:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyring=$(DEBIAN_KEYRING) \
			--variant=container \
			--release=stable \
			--recipes=$(JAVA_RECIPES)/graalvm.sh \
			--scripts=$(SCRIPTS)/security-scan.sh

debian11-graal-slim:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyring=$(DEBIAN_KEYRING) \
			--variant=container \
			--release=stable \
			--recipes=$(JAVA_RECIPES)/graalvm_slim.sh \
			--scripts=$(SCRIPTS)/security-scan.sh

debian11-corretto:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyring=$(DEBIAN_KEYRING) \
			--variant=container \
			--release=stable \
			--recipes=$(JAVA_RECIPES)/corretto.sh \
			--scripts=$(SCRIPTS)/security-scan.sh

debian11-java-slim-maven:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyring=$(DEBIAN_KEYRING) \
			--variant=container \
			--release=stable \
			--recipes=$(JAVA_RECIPES)/java_slim.sh,$(JAVA_RECIPES)/maven.sh \
			--scripts=$(SCRIPTS)/security-scan.sh

debian11-java-slim-gradle:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyring=$(DEBIAN_KEYRING) \
			--variant=container \
			--release=stable \
			--recipes=$(JAVA_RECIPES)/java_slim.sh,$(JAVA_RECIPES)/gradle.sh \
			--scripts=$(SCRIPTS)/security-scan.sh

debian11-graal-slim-maven:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyring=$(DEBIAN_KEYRING) \
			--variant=container \
			--release=stable \
			--recipes=$(JAVA_RECIPES)/graalvm_slim.sh,$(JAVA_RECIPES)/maven.sh \
			--scripts=$(SCRIPTS)/security-scan.sh

debian11-graal-slim-gradle:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyring=$(DEBIAN_KEYRING) \
			--variant=container \
			--release=stable \
			--recipes=$(JAVA_RECIPES)/graalvm_slim.sh,$(JAVA_RECIPES)/gradle.sh \
			--scripts=$(SCRIPTS)/security-scan.sh


debian11-java-kafka:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyring=$(DEBIAN_KEYRING) \
			--variant=container \
			--release=stable \
			--recipes=$(JAVA_RECIPES)/java.sh,$(RECIPES)/kafka/kafka.sh \
			--scripts=$(SCRIPTS)/security-scan.sh

debian11-java-slim-kafka:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyring=$(DEBIAN_KEYRING) \
			--variant=container \
			--release=stable \
			--recipes=$(JAVA_RECIPES)/java_slim.sh,$(RECIPES)/kafka/kafka.sh \
			--scripts=$(SCRIPTS)/security-scan.sh


REQUIRED_TOOLS := docker bash grep sed awk debootstrap unzip
check-dependencies:
	$(PRINT_HEADER)
	@echo "Checking required dependencies..."
	@for tool in $(REQUIRED_TOOLS); do \
 		if ! command -v $$tool >/dev/null 2>&1; then \
 			echo "Error: Required tool '$$tool' is not installed."; \
 		exit 1; \
		else \
 			echo "Found: $$tool"; \
		fi; \
	done
	@echo "All dependencies are satisfied."
