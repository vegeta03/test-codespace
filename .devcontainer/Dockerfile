# Use the official PostgreSQL image based on Debian Bookworm
FROM postgres:17.3-bookworm

# Install prerequisites and build tools including uidmap for newuidmap/newgidmap
RUN apt-get update && apt-get install -y \
    sudo \
    curl \
    wget \
    git \
    ca-certificates \
    build-essential \
    gnupg \
    lsb-release \
    uidmap \
 && rm -rf /var/lib/apt/lists/*

# -------------------------------
# Install Homebrew on Linux
# -------------------------------
# Set environment variables to run the installer noninteractively as root.
ENV NONINTERACTIVE=1
ENV HOMEBREW_INSTALL_AS_ROOT=1

RUN /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Add Homebrew directories to PATH (default locations on Linux)
ENV PATH="/home/linuxbrew/.linuxbrew/bin:/home/linuxbrew/.linuxbrew/sbin:${PATH}"

# -------------------------------
# Install Go 1.24 using Homebrew
# -------------------------------
# Using the formula go@1.24 ensures the precise version is installed.
RUN brew install go@1.24

# Since go@1.24 is keg-only, prepend its opt path to ensure the go binary is found.
ENV PATH="/home/linuxbrew/.linuxbrew/opt/go@1.24/bin:${PATH}"

# Set GOPATH and GOBIN so that go install places binaries in /usr/local/bin.
ENV GOPATH=/go
ENV GOBIN=/usr/local/bin

# -------------------------------
# Install Podman 5.4.0 using Homebrew
# -------------------------------
RUN brew install podman
# Ensure newuidmap and newgidmap have their setuid bits set so rootless operations work
RUN chmod 4755 /usr/bin/newuidmap /usr/bin/newgidmap

# -------------------------------
# Install Kind using go install
# -------------------------------
RUN go install sigs.k8s.io/kind@v0.27.0

# (Optional) You can verify installations during build:
# RUN go version && podman --version && kind version

# The default command of the base postgres image will start the Postgres server
