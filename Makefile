.PHONY: build install

# Build the Docker image (replaces build.sh)
build:
	@docker build -t opencode-ai:latest .

# Install the wrapper script to $HOME/bin and make it executable
install: build
	@mkdir -p "$(HOME)/bin"
	@cp prisoncode "$(HOME)/bin/"
	@chmod +x "$(HOME)/bin/prisoncode"
