# ==============================================================================
# Makefile Configuration Directives
# ==============================================================================

# Set 'help' as the default target when running just 'make'
.DEFAULT_GOAL := help

# Create examples directory structure
examples-dir:
	@mkdir -p examples/{debian,java,nodejs,security,testing}

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
	@echo "General:"
	@echo "  help                 Show this help"
	@echo "  all                  Build all Debian images"
	@echo "  check-dependencies   Check required tools are installed"
	@echo "  clean                Remove build artifacts and downloads"
	@echo "  list-vars            List Makefile variables"
	@echo "  shellcheck           Lint all bash scripts"
	@echo "  package              Create a tar.gz of the repository"
	@echo "  release              Create a git tag and GitHub release"
	@echo "  archive              Create a git archive of HEAD"
	@echo "  bundle               Create a git bundle of the repository"
	@echo "  test                 Run structure tests on container images"
	@echo
	@echo "Debian targets:"
	@echo "  all-debian"
	@echo "  debian11"
	@echo "  debian11-java"
	@echo "  debian11-java-slim"
	@echo "  debian11-corretto"
	@echo "  debian11-graal"
	@echo "  debian11-graal-slim"
	@echo "  debian11-java-slim-maven"
	@echo "  debian11-java-slim-gradle"
	@echo "  debian11-graal-slim-maven"
	@echo "  debian11-graal-slim-gradle"
	@echo "  debian11-nodejs-23.11.0"
	@echo "  debian11-python-3.9.18"
	@echo "  debian11-cuda-runtime"
	@echo

# ==============================================================================
# Build Configuration
# ==============================================================================

SHELL := /bin/bash
.SHELLFLAGS := -o pipefail -ec

THIS_FILE := $(lastword $(MAKEFILE_LIST))
SRCDIR := $(abspath $(patsubst %/,%,$(dir $(THIS_FILE))))
DOWNLOAD_DIR := $(SRCDIR)/download
SCRIPTS_DIR := $(SRCDIR)/scripts
DOCKER_CMD ?= docker

# Debian configuration
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
RELEASE ?= bullseye

# Component versions (override in make command or environment)
JAVA_VERSION ?= 21.0.1
GRAALVM_VERSION ?= 20.0.2
CORRETTO_VERSION ?= 17.0.9.8.1
MAVEN_VERSION ?= 3.8.8
GRADLE_VERSION ?= 7.4.2
NODE_VERSION ?= 23.11.0
PYTHON_VERSION ?= 3.9.18

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

# Toggle inclusion of the security scan script in builds (default: enabled).
# Set CT_DISABLE_SECURITY_SCAN=1/true/yes to omit passing the scan script to mkimage.sh.
CT_DISABLE_SECURITY_SCAN ?=
CT_DISABLE_SECURITY_SCAN_LC := $(shell printf "%s" "$(CT_DISABLE_SECURITY_SCAN)" | tr '[:upper:]' '[:lower:]')
ifneq (,$(filter 1 true yes,$(CT_DISABLE_SECURITY_SCAN_LC)))
  SECURITY_SCAN_ARG :=
else
  SECURITY_SCAN_ARG := --scripts=$(SCRIPTS)/security-scan.sh
endif

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
        debian11-java-slim-gradle debian11-nodejs-23.11.0 \
        debian11-python-3.9.18 debian11-cuda-runtime

.PHONY: all all-debian
.PHONY: help examples-dir check-dependencies clean list-vars debian11-graal-slim-maven debian11-graal-slim-gradle
all: all-debian

all-debian: debian11 debian11-java debian11-java-slim debian11-graal \
     debian11-graal-slim debian11-corretto debian11-java-slim-maven \
     debian11-java-slim-gradle debian11-nodejs-23.11.0 \
     debian11-python-3.9.18


debian11:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyring=$(DEBIAN_KEYRING) \
			--variant=$(VARIANT) \
			--release=$(RELEASE) \
			$(SECURITY_SCAN_ARG)

debian11-java:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyring=$(DEBIAN_KEYRING) \
			--variant=$(VARIANT) \
			--release=$(RELEASE) \
			--recipes=$(JAVA_RECIPES)/java.sh \
			$(SECURITY_SCAN_ARG)

debian11-java-slim:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyring=$(DEBIAN_KEYRING) \
			--variant=$(VARIANT) \
			--release=$(RELEASE) \
			--recipes=$(JAVA_RECIPES)/java_slim.sh \
			$(SECURITY_SCAN_ARG)

debian11-graal:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyring=$(DEBIAN_KEYRING) \
			--variant=$(VARIANT) \
			--release=$(RELEASE) \
			--recipes=$(JAVA_RECIPES)/graalvm.sh \
			$(SECURITY_SCAN_ARG)

debian11-graal-slim:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyring=$(DEBIAN_KEYRING) \
			--variant=$(VARIANT) \
			--release=$(RELEASE) \
			--recipes=$(JAVA_RECIPES)/graalvm_slim.sh \
			$(SECURITY_SCAN_ARG)

debian11-corretto:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyring=$(DEBIAN_KEYRING) \
			--variant=$(VARIANT) \
			--release=$(RELEASE) \
			--recipes=$(JAVA_RECIPES)/corretto.sh \
			$(SECURITY_SCAN_ARG)

debian11-java-slim-maven:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyring=$(DEBIAN_KEYRING) \
			--variant=$(VARIANT) \
			--release=$(RELEASE) \
			--recipes=$(JAVA_RECIPES)/java_slim.sh,$(JAVA_RECIPES)/maven.sh \
			$(SECURITY_SCAN_ARG)

debian11-java-slim-gradle:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyring=$(DEBIAN_KEYRING) \
			--variant=$(VARIANT) \
			--release=$(RELEASE) \
			--recipes=$(JAVA_RECIPES)/java_slim.sh,$(JAVA_RECIPES)/gradle.sh \
			$(SECURITY_SCAN_ARG)

debian11-graal-slim-maven:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyring=$(DEBIAN_KEYRING) \
			--variant=$(VARIANT) \
			--release=$(RELEASE) \
			--recipes=$(JAVA_RECIPES)/graalvm_slim.sh,$(JAVA_RECIPES)/maven.sh \
			$(SECURITY_SCAN_ARG)

debian11-graal-slim-gradle:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyring=$(DEBIAN_KEYRING) \
			--variant=$(VARIANT) \
			--release=$(RELEASE) \
			--recipes=$(JAVA_RECIPES)/graalvm_slim.sh,$(JAVA_RECIPES)/gradle.sh \
			$(SECURITY_SCAN_ARG)





debian11-nodejs-23.11.0:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyring=$(DEBIAN_KEYRING) \
			--variant=$(VARIANT) \
			--release=$(RELEASE) \
			--recipes=$(NODEJS_RECIPES)/nodejs.sh \
			$(SECURITY_SCAN_ARG)

debian11-python-3.9.18:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
                        --name=$@ \
                        --keyring=$(DEBIAN_KEYRING) \
                        --variant=$(VARIANT) \
                        --release=$(RELEASE) \
                        --recipes=$(PYTHON_RECIPES)/python.sh \
                        $(SECURITY_SCAN_ARG)

debian11-cuda-runtime:
	$(PRINT_HEADER)
	$(DEBIAN_BUILD_SCRIPT) \
			--name=$@ \
			--keyring=$(DEBIAN_KEYRING) \
			--variant=$(VARIANT) \
			--release=$(RELEASE) \
			--recipes=$(RECIPES_DIR)/gpu/cuda_runtime.sh \
			$(SECURITY_SCAN_ARG)









# ==============================================================================
# Test Targets
# ==============================================================================

TEST_CONFIG_DIR := $(SRCDIR)/test
CONTAINER_TEST_SCRIPT := $(SCRIPTS_DIR)/test.py

.PHONY: test
test: ## Run structure tests on built container images
	$(PRINT_HEADER)
	@echo "Running structure tests on container images..."
	@for image in $(DIST_DIR)/*; do \
 		if [ -d "$$image" ]; then \
 		image_name=$$(basename $$image); \
		config_file=$(TEST_CONFIG_DIR)/$$image_name.yaml; \
		if [ -f "$$config_file" ]; then \
			echo "Testing image: $$image_name with config: $$config_file"; \
			if ! $(DOCKER_CMD) image inspect $$image_name >/dev/null 2>&1; then \
				echo "Docker image '$$image_name' not found. Importing from tar..."; \
				$(DOCKER_CMD) import "$(DIST_DIR)/$$image_name/$$image_name.tar" "$$image_name"; \
			fi; \
			$(CONTAINER_TEST_SCRIPT) --image $$image_name --config $$config_file; \
		else \
                	echo "No test config found for image: $$image_name"; \
            	fi; \
        	fi; \
    	done
	@echo "All tests completed."

# ==============================================================================
# Utility Targets
# ==============================================================================
REQUIRED_TOOLS := docker bash grep sed awk debootstrap unzip curl perl
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
