FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

# Install required system tools and any dev tools you may need
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    git \
    openssh-client \
    sudo \
    build-essential \
    cmake \
  && rm -rf /var/lib/apt/lists/*


# Create a non-root user
RUN useradd -m -s /bin/bash opencode \
     && echo "opencode ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/opencode \
     && chmod 0440 /etc/sudoers.d/opencode

USER opencode
WORKDIR /home/opencode

# Prepare SSH configuration
RUN mkdir -p /home/opencode/.ssh \
 && touch /home/opencode/.ssh/known_hosts

# Preload GitHub host keys (non-interactive Git usage)
RUN ssh-keyscan -T 5 github.com 2>/dev/null >> /home/opencode/.ssh/known_hosts || true

# Install OpenCode AI (official binary installer)
RUN curl -fsSL https://opencode.ai/install | bash

RUN mkdir -p /home/opencode/.local/share
RUN mkdir -p /home/opencode/.config

CMD ["/home/opencode/.opencode/bin/opencode"]
