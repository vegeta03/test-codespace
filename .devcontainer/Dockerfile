FROM fedora:42

# Install core packages including development tools, Git, Podman, PostgreSQL and curl
RUN dnf install -y \
    make \
    gcc \
    sudo \
    git \
    golang \
    podman \
    postgresql-server \
    postgresql-contrib \
    curl \
    && dnf clean all

# Set up Go environment variables
ENV GOPATH=/go
ENV PATH=$PATH:/usr/local/go/bin:/go/bin

# Install Kind for Kubernetes clustering
RUN curl -Lo /usr/local/bin/kind https://kind.sigs.k8s.io/dl/v0.27.0/kind-linux-amd64 \
    && chmod +x /usr/local/bin/kind

# Create PostgreSQL directories and ensure correct ownership
RUN mkdir -p /var/lib/pgsql && chown -R postgres:postgres /var/lib/pgsql

# Receive POSTGRES_PASSWORD as a build argument and create a secure temporary password file for initdb
ARG POSTGRES_PASSWORD
RUN echo "${POSTGRES_PASSWORD}" > /tmp/pgpass && \
    chmod 600 /tmp/pgpass && \
    chown postgres:postgres /tmp/pgpass

# Switch to the postgres user to initialize the database cluster
USER postgres
RUN initdb -D /var/lib/pgsql/data \
    --auth-host=scram-sha-256 \
    --auth-local=scram-sha-256 \
    --username=postgres \
    --pwfile=/tmp/pgpass && \
    echo "host all all all scram-sha-256" >> /var/lib/pgsql/data/pg_hba.conf && \
    echo "listen_addresses = '*'" >> /var/lib/pgsql/data/postgresql.conf && \
    mkdir -p /var/lib/pgsql/data/log && \
    chmod 700 /var/lib/pgsql/data

# Set PGDATA environment variable so that PostgreSQL knows where its data lives
ENV PGDATA=/var/lib/pgsql/data

# Switch back to root to configure the workspace and create a non-root VS Code user
USER root
RUN mkdir -p /workspace && \
    useradd -m vscode && \
    usermod -aG wheel vscode && \
    echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers && \
    chown -R vscode:vscode /workspace

# Switch to the vscode user and set the default working directory
USER vscode
WORKDIR /workspace
