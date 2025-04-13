# ==============================================================================
# Phony Targets
# ==============================================================================
.PHONY: help all check-dependencies shellcheck qemu-user-static \
        debian-base debian-java debian-java-slim debian-graal \
        debian-corretto debian-java-slim-maven debian-java-slim-gradle \
        debian-java-kafka debian-java-slim-kafka clean

.DEFAULT_GOAL := help
.ONESHELL:
.EXPORT_ALL_VARIABLES:

ifndef VERBOSE
.SILENT:
endif

include Makefile.inc

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
	@echo " * 'check-dependencies' - Check for required tools and dependencies"
	@echo " * 'clean' - Remove all build artifacts and downloaded files"
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
	@echo	
	@echo "|debian11-java-kafka|"
	@echo "|debian11-java-slim-kafka|"
	@echo	
	@echo "|debian11-nodejs|"

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

all:debian11 debian11-java debian11-java-slim debian11-graal debian11-graal-slim debian11-corretto debian11-java-slim-maven debian11-java-slim-gradle debian11-nodejs debian11-java-slim-kafka debian11-java-kafka

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


debian11-nodejs:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyring=$(DEBIAN_KEYRING) \
			--variant=container \
			--release=stable \
			--recipes=$(RECIPES)/nodejs/nodejs.sh \
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


DOWNLOADS_DIR := download
DIST_DIR := debian/dist

clean: ## Remove all build artifacts and downloads
	@echo -e "Cleaning build artifacts and downloads..."
	@if [ -d "$(DIST_DIR)" ]; then \
		echo -e "Removing distributions..."; \
		rm -rf $(DIST_DIR)/*; \
	fi
	@if [ -d "$(DOWNLOADS_DIR)" ]; then \
		echo -e "Removing downloaded files..."; \
		rm -rf $(DOWNLOADS_DIR)/*; \
	fi

.PHONY: list-vars
list-vars:
	@echo "Variable Name       Origin"
	@echo "-------------------- -----------"
	@$(foreach var, $(filter-out .% %_FILES, $(.VARIABLES)), \
		$(if $(filter-out default automatic, $(origin $(var))), \
			printf "%-20s %s\\n" "$(var)" "$(origin $(var))"; \
		))

GIT_BRANCH := $(shell git rev-parse --abbrev-ref HEAD)
GIT_COMMIT := $(shell git rev-parse --short HEAD)

.PHONY: package
package:
	@echo "Creating a tar.gz archive of the entire directory..."
	@DIR_NAME=$$(basename $$(pwd)); \
	TAR_FILE="$$DIR_NAME.tar.gz"; \
	tar -czvf $$TAR_FILE .; \
	echo "Archive created successfully: $$TAR_FILE"

.PHONY: release
release:
	@echo "Creating Git tag and releasing on GitHub..."
	@read -p "Enter the version number (e.g., v1.0.0): " version; \
	git tag -a $$version -m "Release $$version"; \
	git push origin $$version; \
	gh release create $$version --generate-notes
	@echo "Release $$version created and pushed to GitHub."

.PHONY: archive
archive:
	@echo "Creating git archive..."
	git archive --format=tar.gz --output=archive-$(GIT_BRANCH)-$(GIT_COMMIT).tar.gz HEAD
	@echo "Archive created: archive-$(GIT_BRANCH)-$(GIT_COMMIT).tar.gz"

.PHONY: bundle
bundle:
	@echo "Creating git bundle..."
	git bundle create bundle-$(GIT_BRANCH)-$(GIT_COMMIT).bundle --all
	@echo "Bundle created: bundle-$(GIT_BRANCH)-$(GIT_COMMIT).bundle"
