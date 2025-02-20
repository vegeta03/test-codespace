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

# Set Go environment
ENV GOPATH=/go PATH=$PATH:/usr/local/go/bin:/go/bin

# Install Kind for Kubernetes clustering
RUN curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.27.0/kind-linux-amd64 \
    && chmod +x ./kind \
    && mv ./kind /usr/local/bin/kind

# Create PostgreSQL base directory and adjust ownership
RUN mkdir -p /var/lib/pgsql \
    && chown -R postgres:postgres /var/lib/pgsql

# Create a password file using build argument; secure it properly
ARG POSTGRES_PASSWORD
RUN echo "${POSTGRES_PASSWORD}" > /tmp/pgpass \
    && chmod 600 /tmp/pgpass \
    && chown postgres:postgres /tmp/pgpass

# Switch to postgres user to initialize the database
USER postgres
RUN initdb -D /var/lib/pgsql/data \
    --auth-host=scram-sha-256 \
    --auth-local=scram-sha-256 \
    --username=postgres \
    --pwfile=/tmp/pgpass \
    && echo "host all all all scram-sha-256" >> /var/lib/pgsql/data/pg_hba.conf \
    && echo "listen_addresses = '*'" >> /var/lib/pgsql/data/postgresql.conf \
    && mkdir -p /var/lib/pgsql/data/log

# (Optional) Set PGDATA environment variable for clarity
ENV PGDATA=/var/lib/pgsql/data

# Switch back to root for further configuration
USER root

# Ensure /workspace exists before changing its ownership
RUN mkdir -p /workspace \
    && useradd -m vscode \
    && usermod -aG wheel vscode \
    && echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers \
    && chown -R vscode:vscode /workspace

# Set final user and working directory
USER vscode
WORKDIR /workspace
