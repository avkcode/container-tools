PODMAN? := $(shell podman --version 2>/dev/null)
ifdef DOCKER?
	DOCKER := podman
else
	DOCKER := docker
endif

shellcheck:
	@shellcheck --severity=error --enable=all --shell=bash $(shell find . -type f -name "*.sh")

qemu-user-static:
	$(DOCKER) run --rm --privileged multiarch/qemu-user-static:register --reset


# Path to your Cosign private key
COSIGN_KEY := /path/to/cosign.key  # Replace with the actual path to your cosign.key file

# Target to sign .tar files in */dist using Cosign
sign-tar-files:
	@echo "Signing .tar files in debian/dist with Cosign..."
	@if ! command -v cosign > /dev/null 2>&1; then \
		echo "Cosign is not installed. Please install it from https://github.com/sigstore/cosign."; \
		exit 1; \
	fi
	@if [ ! -f "$(COSIGN_KEY)" ]; then \
		echo "Cosign private key not found at $(COSIGN_KEY). Please generate a key pair using 'cosign generate-key-pair'."; \
		exit 1; \
	fi
	@for file in $$(find debian/dist -type f -name "*.tar"); do \
		echo "Signing $$file..."; \
		cosign sign-blob --key "$(COSIGN_KEY)" $$file --output-signature $$file.sig --output-certificate $$file.crt; \
		if [ $$? -eq 0 ]; then \
			echo "Successfully signed $$file."; \
		else \
			echo "Failed to sign $$file."; \
			exit 1; \
		fi; \
	done
