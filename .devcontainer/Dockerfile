# .devcontainer/Dockerfile
FROM fedora:42

# Install core packages
RUN dnf install -y \
    git \
    podman \
    postgresql-server \
    postgresql-contrib \
    make \
    gcc \
    sudo \
    && dnf clean all

# Set environment for Go
ENV GOPATH=/go PATH=$PATH:/usr/local/go/bin:/go/bin

# Install Kind for Kubernetes cluster creation
RUN curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.27.0/kind-linux-amd64 \
    && chmod +x ./kind \
    && mv ./kind /usr/local/bin/kind

# Configure PostgreSQL base directory; do not pre-create the data directory
RUN mkdir -p /var/lib/pgsql \
    && chown -R postgres:postgres /var/lib/pgsql

# Create password file with build argument; ensure proper permissions
ARG POSTGRES_PASSWORD
RUN echo "${POSTGRES_PASSWORD}" > /tmp/pgpass \
    && chmod 600 /tmp/pgpass \
    && chown postgres:postgres /tmp/pgpass

# Switch to postgres user to initialize the database cluster
USER postgres
RUN initdb -D /var/lib/pgsql/data \
    --auth-host=scram-sha-256 \
    --auth-local=scram-sha-256 \
    --username=postgres \
    --pwfile=/tmp/pgpass \
    && echo "host all all all scram-sha-256" >> /var/lib/pgsql/data/pg_hba.conf \
    && echo "listen_addresses = '*'" >> /var/lib/pgsql/data/postgresql.conf \
    && mkdir -p /var/lib/pgsql/data/log  # Create log directory after initdb

# Switch back to root for user configuration and workspace setup
USER root

# Create the /workspace directory before attempting to change its ownership.
RUN mkdir -p /workspace \
    && useradd -m vscode \
    && usermod -aG wheel vscode \
    && echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers \
    && chown -R vscode:vscode /workspace

# Set the default user and working directory
USER vscode
WORKDIR /workspace
