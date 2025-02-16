PODMAN? := $(shell podman --version 2>/dev/null)
ifdef DOCKER?
	DOCKER := podman
else
	DOCKER := docker
endif

shellcheck:
	@echo "Installing shellcheck..."
	@if command -v apt-get > /dev/null 2>&1; then \
        	sudo apt-get install -y shellcheck; \
    	elif command -v brew > /dev/null 2>&1; then \
        	brew install shellcheck; \
    	else \
        	echo "Unsupported package manager. Please install shellcheck manually from https://github.com/koalaman/shellcheck."; \
        exit 1; \
    	fi
	@shellcheck --severity=error --enable=all --shell=bash $(shell find . -type f -name "*.sh")

qemu-user-static:
	$(DOCKER) run --rm --privileged multiarch/qemu-user-static:register --reset
