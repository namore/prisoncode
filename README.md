# Prisoncode

**Prisoncode** is a thin wrapper around **opencode** that runs the tool inside a Docker container. The container provides a sandboxed environment, exposing only the current working directory plus the opencode auth and configuration files. This approach improves security by preventing opencode from accessing or modifying files outside of its designated workspace.

The original implementation was based on the blog post:

> https://www.nuface.tw/running-opencode-ai-using-docker-2/

---

## Platform support

The wrapper is designed to be **platform‑independent**. It includes UID/GID mapping via `fixuid` to avoid permission issues when running on Linux or WSL. Contributions to improve cross‑platform compatibility are welcome.

---

## Usage

Once installed, simply replace calls to `opencode` with `prisoncode`:

```bash
prisoncode <args>
```

The command behaves exactly like `opencode` but runs inside the Docker container, keeping the host system safe.

The container runs as a non-root user and maps your host UID/GID. Only `auth.json` and the opencode config directory are mounted, and both are mounted read-only.

> **Note:** If your workflow requires additional compilers or build tools, you must add them manually to the `Dockerfile`.

---

## Installation

For optional custom package installation, see the **Custom package list** section below.

```bash
# Build the Docker image
make build

# Install the wrapper script to $HOME/bin (add it to your PATH)
make install
```

After running `make install`, the `prisoncode` executable will be available in `~/bin`. Ensure that `~/bin` is on your `PATH` or invoke it with the full path.



---

## Custom package list

`prisoncode` can install additional Ubuntu 24.04 packages inside the Docker container based on a user‑defined list. The list is read from:

```
$HOME/.prisoncode/packages.txt
```

### Format
* One package per line.
* Lines starting with `#` are treated as comments and ignored.
* Empty lines are ignored.

Example:

```text
# Packages required for my project
git
curl
ffmpeg
```

When the wrapper runs it checks a SHA‑256 hash of this file against a hash stored in the Docker image. If the file has changed, you will see a warning:

```
⚠️  ~/.prisoncode/packages.txt has changed since the Docker image was built.
   Run 'prisoncode -r' (or '--reinstall') to rebuild the container.
```

### Rebuilding the image
After editing `packages.txt`, rebuild the Docker image (and update the cached hash) with the `--reinstall` flag:

```bash
prisoncode -r
```

This triggers `make install`, which rebuilds the image using the current package list.

> **Note:** The packages must be available for Ubuntu 24.04 (as used by the container) and can be installed via `apt-get install <name>`.

## Contributing & Issues

Issues, feature requests, and pull requests are welcome! Please file them on the GitHub repository.

---

## License

This work is dedicated to the public domain under the CC0 1.0 Universal (CC0 1.0) Public Domain Dedication. You can find the full text at https://creativecommons.org/publicdomain/zero/1.0/
