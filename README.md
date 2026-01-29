# Prisoncode

**Prisoncode** is a thin wrapper around **opencode** that runs the tool inside a Docker container. The container provides a sandboxed environment, exposing only the current working directory and the opencode configuration and session files. This approach improves security by preventing opencode from accessing or modifying files outside of its designated workspace.

The original implementation was based on the blog post:

> https://www.nuface.tw/running-opencode-ai-using-docker-2/

---

## Platform support

The wrapper is designed to be **platform‑independent**, but it has only been tested on **macOS** so far. Testing on other operating systems (Linux, Windows) is still pending. Contributions to improve cross‑platform compatibility are welcome.

---

## Usage

Once installed, simply replace calls to `opencode` with `prisoncode`:

```bash
prisoncode <args>
```

The command behaves exactly like `opencode` but runs inside the Docker container, keeping the host system safe.

> **Note:** If your workflow requires additional compilers or build tools, you must add them manually to the `Dockerfile`.

---

## Installation

```bash
# Build the Docker image
make build

# Install the wrapper script to $HOME/bin (add it to your PATH)
make install
```

After running `make install`, the `prisoncode` executable will be available in `~/bin`. Ensure that `~/bin` is on your `PATH` or invoke it with the full path.

---

## Contributing & Issues

Issues, feature requests, and pull requests are welcome! Please file them on the GitHub repository.

---

## License

This work is dedicated to the public domain under the CC0 1.0 Universal (CC0 1.0) Public Domain Dedication. You can find the full text at https://creativecommons.org/publicdomain/zero/1.0/
