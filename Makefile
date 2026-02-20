.PHONY: build test install

# User package list (default location)
USER_PKGS_FILE ?= $(HOME)/.prisoncode/packages.txt
USER_PKGS := $(shell grep -v '^\#' $(USER_PKGS_FILE) 2>/dev/null)

# Compute SHA‑256 hash of the packages file (empty string if missing)
PKGS_HASH := $(shell if [ -f $(HOME)/.prisoncode/packages.txt ]; then \
                 shasum -a 256 $(HOME)/.prisoncode/packages.txt | awk '{print $$1}'; \
               else echo ""; fi)

# Build the Docker image (replaces build.sh)
build:
	@docker build \
		--build-arg USER_PKGS="$(USER_PKGS)" \
		--build-arg PKGS_HASH="$(PKGS_HASH)" \
		--build-arg REPO_PATH="$(PWD)" \
		-t prisoncode:latest .

test:
	@sh scripts/selftest-prisoncode-validations.sh

INSTALL_DEPS := build
ifneq ($(SKIP_TESTS),1)
INSTALL_DEPS := test build
endif

# Install the wrapper script to $HOME/bin and make it executable
install: $(INSTALL_DEPS)
	@mkdir -p "$(HOME)/bin"
	@cp prisoncode "$(HOME)/bin/"
	@chmod +x "$(HOME)/bin/prisoncode"
