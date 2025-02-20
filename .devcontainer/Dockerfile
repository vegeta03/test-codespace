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

# Configure PostgreSQL directories
RUN mkdir -p /var/lib/pgsql/data/log \
    && chown -R postgres:postgres /var/lib/pgsql

# Initialize DB as postgres user
USER postgres
RUN initdb -D /var/lib/pgsql/data \
    --auth-host=scram-sha-256 \
    --auth-local=scram-sha-256 \
    --pgdata=/var/lib/pgsql/data \
    --username=postgres \
    --pwfile=/tmp/pgpass \
    && echo "host all all all scram-sha-256" >> /var/lib/pgsql/data/pg_hba.conf \
    && echo "listen_addresses = '*'" >> /var/lib/pgsql/data/postgresql.conf

# Configure container user
USER root
RUN useradd -m vscode \
    && usermod -aG wheel vscode \
    && echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers \
    && chown -R vscode:vscode /workspace

USER vscode
WORKDIR /workspace
