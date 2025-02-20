FROM fedora:42

# Install core packages
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

# Set up Go environment
ENV GOPATH=/go
ENV PATH=$PATH:/usr/local/go/bin:/go/bin

# Install Kind
RUN curl -Lo /usr/local/bin/kind https://kind.sigs.k8s.io/dl/v0.27.0/kind-linux-amd64 \
    && chmod +x /usr/local/bin/kind

# PostgreSQL setup
RUN mkdir -p /var/lib/pgsql && \
    chown -R postgres:postgres /var/lib/pgsql && \
    mkdir -p /run/postgresql && \
    chown postgres:postgres /run/postgresql

ARG POSTGRES_PASSWORD
RUN echo "${POSTGRES_PASSWORD}" > /tmp/pgpass && \
    chmod 600 /tmp/pgpass && \
    chown postgres:postgres /tmp/pgpass

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

USER root
RUN rm -f /tmp/pgpass && \
    mkdir -p /workspace && \
    useradd -m vscode && \
    usermod -aG wheel vscode && \
    echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers && \
    chown -R vscode:vscode /workspace

COPY setup.sh /usr/local/bin/setup.sh
RUN sudo chmod +x /usr/local/bin/setup.sh

USER vscode
WORKDIR /workspace
