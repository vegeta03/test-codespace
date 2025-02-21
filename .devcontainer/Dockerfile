# Use the official PostgreSQL image based on Debian Bookworm
FROM postgres:17.3-bookworm

# Install prerequisites and build tools
RUN apt-get update && apt-get install -y \
    curl \
    wget \
    git \
    ca-certificates \
    build-essential \
    gnupg \
    lsb-release && \
    rm -rf /var/lib/apt/lists/*

# -------------------------------
# Install Go 1.24
# -------------------------------
RUN wget https://go.dev/dl/go1.24.linux-amd64.tar.gz && \
    rm -rf /usr/local/go && \
    tar -C /usr/local -xzf go1.24.linux-amd64.tar.gz && \
    rm go1.24.linux-amd64.tar.gz
# Update PATH to include Go
ENV PATH="/usr/local/go/bin:${PATH}"

# -------------------------------
# Install Podman 5.4.0
# -------------------------------
# (For demonstration, we assume a release archive is available at the URL below)
RUN wget https://github.com/containers/podman/releases/download/v5.4.0/podman-5.4.0-linux-x86_64.tar.gz && \
    tar -xzvf podman-5.4.0-linux-x86_64.tar.gz -C /usr/local/bin --strip-components=1 && \
    rm podman-5.4.0-linux-x86_64.tar.gz

# -------------------------------
# Setup Go environment for installing Kind
# -------------------------------
# Set GOPATH and GOBIN so that go install places binaries in /usr/local/bin.
ENV GOPATH=/go
ENV GOBIN=/usr/local/bin

# Install Kind using go install
RUN go install sigs.k8s.io/kind@v0.27.0

# (Optional) Verify installations during build if desired:
# RUN go version && podman --version && kind version

# The default command of the base postgres image will start the Postgres server
