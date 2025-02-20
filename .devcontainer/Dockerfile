FROM fedora:42

# Install systemd for proper service management
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
    systemd \
    && dnf clean all \
    && systemctl mask dev-hugepages.mount sys-fs-fuse-connections.mount

# Configure systemd for container compatibility
RUN (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
    rm -f /lib/systemd/system/multi-user.target.wants/*;\
    rm -f /etc/systemd/system/*.wants/*;\
    rm -f /lib/systemd/system/local-fs.target.wants/*; \
    rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
    rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
    rm -f /lib/systemd/system/basic.target.wants/*;\
    rm -f /lib/systemd/system/anaconda.target.wants/*;

# Configure PostgreSQL with systemd integration
RUN systemctl enable postgresql

# Setup database with explicit initialization
ARG POSTGRES_PASSWORD=devpass
RUN mkdir -p /var/lib/pgsql/data && \
    chown postgres:postgres /var/lib/pgsql/data && \
    sudo -u postgres initdb -D /var/lib/pgsql/data \
        --auth-host=scram-sha-256 \
        --auth-local=scram-sha-256 && \
    echo "host all all all scram-sha-256" >> /var/lib/pgsql/data/pg_hba.conf && \
    echo "listen_addresses = '*'" >> /var/lib/pgsql/data/postgresql.conf

# Configure persistent environment variables
ENV GOPATH=/go \
    PATH=$PATH:/usr/local/go/bin:/go/bin \
    PGDATA=/var/lib/pgsql/data \
    POSTGRES_PASSWORD=${POSTGRES_PASSWORD}

# Install Kind with version pinning
RUN curl -Lo /usr/local/bin/kind https://kind.sigs.k8s.io/dl/v0.27.0/kind-linux-amd64 \
    && chmod +x /usr/local/bin/kind

# Create non-root user with explicit UID/GID mapping
RUN useradd -m -s /bin/bash -u 1000 vscode && \
    usermod -aG wheel vscode && \
    echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers && \
    mkdir -p /workspace && \
    chown -R vscode:vscode /workspace

WORKDIR /workspace
USER vscode
