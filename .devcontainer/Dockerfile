# Use Fedora as a proxy for a Fedora CoreOS environment
FROM fedora:42

# Install required tools and dependencies
RUN dnf update -y && \
    dnf install -y wget tar git podman curl && \
    dnf clean all

# Install Go 1.24
RUN wget https://go.dev/dl/go1.24.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.24.linux-amd64.tar.gz && \
    rm go1.24.linux-amd64.tar.gz

# Update PATH to include Go binary
ENV PATH="/usr/local/go/bin:${PATH}"

# Install Kind (using an example version; adjust version as needed)
RUN curl -Lo /usr/local/bin/kind https://kind.sigs.k8s.io/dl/v0.17.0/kind-linux-amd64 && \
    chmod +x /usr/local/bin/kind

# Set the working directory for development
WORKDIR /workspace

# Expose any ports if necessary (e.g. for Go webservers)
EXPOSE 8080
