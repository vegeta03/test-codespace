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

# Configure Go environment
ENV GOPATH=/go PATH=$PATH:/usr/local/go/bin:/go/bin

# Install Kind
RUN curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.27.0/kind-linux-amd64 \
    && chmod +x ./kind \
    && mv ./kind /usr/local/bin/kind

# Configure PostgreSQL base directory (without creating data subdirectory)
RUN mkdir -p /var/lib/pgsql \
    && chown -R postgres:postgres /var/lib/pgsql

# Create password file before switching users
ARG POSTGRES_PASSWORD
RUN echo "${POSTGRES_PASSWORD}" > /tmp/pgpass \
    && chmod 600 /tmp/pgpass \
    && chown postgres:postgres /tmp/pgpass

# Initialize DB as postgres user
USER postgres
RUN initdb -D /var/lib/pgsql/data \
    --auth-host=scram-sha-256 \
    --auth-local=scram-sha-256 \
    --username=postgres \
    --pwfile=/tmp/pgpass \
    && echo "host all all all scram-sha-256" >> /var/lib/pgsql/data/pg_hba.conf \
    && echo "listen_addresses = '*'" >> /var/lib/pgsql/data/postgresql.conf \
    && mkdir -p /var/lib/pgsql/data/log  # Create log dir after initdb

# Configure container user
USER root
RUN useradd -m vscode \
    && usermod -aG wheel vscode \
    && echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers \
    && chown -R vscode:vscode /workspace

USER vscode
WORKDIR /workspace
