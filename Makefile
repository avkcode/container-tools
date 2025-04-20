# ==============================================================================
# Makefile Configuration Directives
# ==============================================================================

# Set 'help' as the default target when running just 'make'
.DEFAULT_GOAL := help

# Run all recipe lines in one shell (enables using shell variables across lines)
.ONESHELL:

# Automatically export all variables to recipe shells
.EXPORT_ALL_VARIABLES:

# Suppress command echoing unless VERBOSE=1 is set
ifndef VERBOSE
.SILENT:
endif

.DELETE_ON_ERROR: # Delete target files if recipe fails
# ==============================================================================
# Help
# ==============================================================================
help:
	@echo
	@echo "Usage: make <target>"
	@echo
	@echo "  help               - Display this help message"
	@echo "  all                - Build all Debian images"
	@echo "  check-dependencies - Verify required tools are installed"
	@echo "  clean              - Remove all build artifacts and downloads"
	@echo "  list-vars          - List all Makefile variables and their origins"
	@echo "  shellcheck         - Validate all bash scripts"
	@echo "  package   	     - Create tar.gz archive of the directory"
	@echo "  release            - Create Git tag and GitHub release"
	@echo "  archive            - Create git archive of HEAD"
	@echo "  bundle             - Create git bundle of repository"
	@echo
	@echo " ============================"
	@echo "  ** Debian Linux targets ** "
	@echo " ============================"
	@echo
	@echo "|all|"
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
	@echo	
	@echo "|debian11-java-kafka|"
	@echo "|debian11-java-slim-kafka|"
	@echo	
	@echo "|debian11-nodejs-23.11.0|"
	@echo
	@echo "|debian11-python-3.9.18|"

# ==============================================================================
# Build Configuration
# ==============================================================================

SHELL := /bin/bash
.SHELLFLAGS := -o pipefail -ec

THIS_FILE := $(lastword $(MAKEFILE_LIST))
SRCDIR := $(abspath $(patsubst %/,%,$(dir $(THIS_FILE))))
DOWNLOAD_DIR := $(SRCDIR)/download
SCRIPTS_DIR := $(SRCDIR)/scripts

DEBIAN_DIR := $(SRCDIR)/debian
DEBIAN_BUILD_SCRIPT := $(DEBIAN_DIR)/mkimage.sh
DEBIAN_KEYS_DIR := $(DEBIAN_DIR)/keys
DEBIAN_KEYRING := $(DEBIAN_KEYS_DIR)/debian-archive-keyring.gpg

# Validate keyring exists
ifeq (,$(wildcard $(DEBIAN_KEYRING)))
  $(error Debian keyring not found at $(DEBIAN_KEYRING))
endif

# Build options
VARIANT ?= container
RELEASE ?= stable

# Validate VARIANT
VALID_VARIANTS := container fakechroot minbase
ifneq (,$(filter-out $(VALID_VARIANTS),$(VARIANT)))
  $(error Invalid VARIANT '$(VARIANT)'. Must be one of: $(VALID_VARIANTS))
endif

# Version information
VERSION := $(shell git describe --tags 2>/dev/null || echo "0.1.0")
BUILD_DATE := $(shell date -u +"%Y-%m-%dT%H:%M:%SZ")
GIT_REVISION := $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")

# Export for child processes
export VERSION BUILD_DATE GIT_REVISION

COLOR_RESET := \033[0m
COLOR_GREEN := \033[32m
COLOR_YELLOW := \033[33m

# Print header with timestamp and color
PRINT_HEADER = @printf "$(COLOR_GREEN)\n[%s] %-60s$(COLOR_RESET)\n" "$$(date +'%Y-%m-%d %H:%M:%S')" "Building: $@"

# Recipes
SCRIPTS := $(SRCDIR)/scripts/
RECIPES_DIR := $(SRCDIR)/recipes
JAVA_RECIPES := $(RECIPES_DIR)/java/
PYTHON_RECIPES := $(RECIPES_DIR)/python/
NODEJS_RECIPES := $(RECIPES_DIR)/nodejs/

# ==============================================================================
# Build Targets
# ==============================================================================

.PHONY: debian11 debian11-java debian11-java-slim debian11-graal \
        debian11-graal-slim debian11-corretto debian11-java-slim-maven \
        debian11-java-slim-gradle debian11-nodejs-23.11.0 debian11-java-slim-kafka \
        debian11-java-kafka debian11-python-3.9.18

.PHONY: all
all: debian11 debian11-java debian11-java-slim debian11-graal \
     debian11-graal-slim debian11-corretto debian11-java-slim-maven \
     debian11-java-slim-gradle debian11-nodejs-23.11.0 debian11-java-slim-kafka \
     debian11-java-kafka debian11-python-3.9.18

debian11:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyring=$(DEBIAN_KEYRING) \
			--variant=$(VARIANT) \
			--release=$(RELEASE) \
			--scripts=$(SCRIPTS)/security-scan.sh

debian11-java:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyring=$(DEBIAN_KEYRING) \
			--variant=$(VARIANT) \
			--release=$(RELEASE) \
			--recipes=$(JAVA_RECIPES)/java.sh \
			--scripts=$(SCRIPTS)/security-scan.sh

debian11-java-slim:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyring=$(DEBIAN_KEYRING) \
			--variant=$(VARIANT) \
			--release=$(RELEASE) \
			--recipes=$(JAVA_RECIPES)/java_slim.sh \
			--scripts=$(SCRIPTS)/security-scan.sh

debian11-graal:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyring=$(DEBIAN_KEYRING) \
			--variant=$(VARIANT) \
			--release=$(RELEASE) \
			--recipes=$(JAVA_RECIPES)/graalvm.sh \
			--scripts=$(SCRIPTS)/security-scan.sh

debian11-graal-slim:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyring=$(DEBIAN_KEYRING) \
			--variant=$(VARIANT) \
			--release=$(RELEASE) \
			--recipes=$(JAVA_RECIPES)/graalvm_slim.sh \
			--scripts=$(SCRIPTS)/security-scan.sh

debian11-corretto:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyring=$(DEBIAN_KEYRING) \
			--variant=$(VARIANT) \
			--release=$(RELEASE) \
			--recipes=$(JAVA_RECIPES)/corretto.sh \
			--scripts=$(SCRIPTS)/security-scan.sh

debian11-java-slim-maven:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyring=$(DEBIAN_KEYRING) \
			--variant=$(VARIANT) \
			--release=$(RELEASE) \
			--recipes=$(JAVA_RECIPES)/java_slim.sh,$(JAVA_RECIPES)/maven.sh \
			--scripts=$(SCRIPTS)/security-scan.sh

debian11-java-slim-gradle:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyring=$(DEBIAN_KEYRING) \
			--variant=$(VARIANT) \
			--release=$(RELEASE) \
			--recipes=$(JAVA_RECIPES)/java_slim.sh,$(JAVA_RECIPES)/gradle.sh \
			--scripts=$(SCRIPTS)/security-scan.sh

debian11-graal-slim-maven:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyring=$(DEBIAN_KEYRING) \
			--variant=$(VARIANT) \
			--release=$(RELEASE) \
			--recipes=$(JAVA_RECIPES)/graalvm_slim.sh,$(JAVA_RECIPES)/maven.sh \
			--scripts=$(SCRIPTS)/security-scan.sh

debian11-graal-slim-gradle:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyring=$(DEBIAN_KEYRING) \
			--variant=$(VARIANT) \
			--release=$(RELEASE) \
			--recipes=$(JAVA_RECIPES)/graalvm_slim.sh,$(JAVA_RECIPES)/gradle.sh \
			--scripts=$(SCRIPTS)/security-scan.sh


debian11-java-kafka:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyring=$(DEBIAN_KEYRING) \
			--variant=$(VARIANT) \
			--release=$(RELEASE) \
			--recipes=$(JAVA_RECIPES)/java.sh,$(RECIPES)/kafka/kafka.sh \
			--scripts=$(SCRIPTS)/security-scan.sh

debian11-java-slim-kafka:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyring=$(DEBIAN_KEYRING) \
			--variant=$(VARIANT) \
			--release=$(RELEASE) \
			--recipes=$(JAVA_RECIPES)/java_slim.sh,$(RECIPES)/kafka/kafka.sh \
			--scripts=$(SCRIPTS)/security-scan.sh


debian11-nodejs-23.11.0:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyring=$(DEBIAN_KEYRING) \
			--variant=$(VARIANT) \
			--release=$(RELEASE) \
			--recipes=$(NODEJS_RECIPES)/nodejs.sh \
			--scripts=$(SCRIPTS)/security-scan.sh

debian11-python-3.9.18:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
                        --name=$@ \
                        --keyring=$(DEBIAN_KEYRING) \
                        --variant=$(VARIANT) \
                        --release=$(RELEASE) \
                        --recipes=$(PYTHON_RECIPES)/python.sh \
                        --scripts=$(SCRIPTS)/security-scan.sh

debian11-php-8.2.12:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyring=$(DEBIAN_KEYRING) \
			--variant=$(VARIANT) \
			--release=$(RELEASE) \
			--recipes=$(RECIPES_DIR)/php/php.sh \
			--scripts=$(SCRIPTS)/security-scan.sh


# ==============================================================================
# Utility Targets
# ==============================================================================
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

.PHONY: shellcheck
shellcheck:
	@shellcheck --severity=error --enable=all --shell=bash $(shell find . -type f -name "*.sh")
