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

# Use existing non-root user
RUN echo "ubuntu ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/ubuntu \
     && chmod 0440 /etc/sudoers.d/ubuntu

RUN curl -SsL https://github.com/boxboat/fixuid/releases/download/v0.6.0/fixuid-0.6.0-linux-amd64.tar.gz | tar -C /usr/local/bin -xzf - && \
    chown root:root /usr/local/bin/fixuid && \
    chmod 4755 /usr/local/bin/fixuid && \
    mkdir -p /etc/fixuid && \
    printf "user: ubuntu\ngroup: ubuntu\n" > /etc/fixuid/config.yml

USER ubuntu:ubuntu
WORKDIR /home/ubuntu

# Prepare SSH configuration
RUN mkdir -p /home/ubuntu/.ssh \
 && touch /home/ubuntu/.ssh/known_hosts

# Preload GitHub host keys (non-interactive Git usage)
RUN ssh-keyscan -T 5 github.com 2>/dev/null >> /home/ubuntu/.ssh/known_hosts || true

# Install OpenCode AI (official binary installer)
RUN curl -fsSL https://opencode.ai/install | bash

RUN mkdir -p /home/ubuntu/.local/share/opencode
RUN mkdir -p /home/ubuntu/.config

ENTRYPOINT ["fixuid"]
CMD ["/home/ubuntu/.opencode/bin/opencode"]
