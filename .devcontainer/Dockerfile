FROM fedora:42

RUN dnf install -y \
    wget \
    curl \
    tar \
    make \
    gcc \
    sudo \
    git \
    golang \
    podman \
    && dnf clean all

# Set up Go environment
ENV GOPATH=/go
ENV PATH=$PATH:/usr/local/go/bin:/go/bin

# Install Kind
RUN curl -Lo /usr/local/bin/kind https://kind.sigs.k8s.io/dl/v0.27.0/kind-linux-amd64 \
    && chmod +x /usr/local/bin/kind

# Create workspace and set permissions
RUN mkdir /workspace && chmod 777 /workspace
WORKDIR /workspace

# Expose any ports if necessary (e.g. for Go webservers)
EXPOSE 8080

# Keep container running
CMD ["tail", "-f", "/dev/null"]