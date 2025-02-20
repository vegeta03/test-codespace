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

# Configure Go
ENV GOPATH=/go PATH=$PATH:/usr/local/go/bin:/go/bin

# Install Kind
RUN curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.27.0/kind-linux-amd64 \
    && chmod +x ./kind \
    && mv ./kind /usr/local/bin/kind

# PostgreSQL Manual Setup
RUN mkdir -p /var/lib/pgsql/data \
    && chown -R postgres:postgres /var/lib/pgsql \
    && sudo -u postgres initdb -D /var/lib/pgsql/data --auth-host=scram-sha-256 \
    && echo "host all all all scram-sha-256" >> /var/lib/pgsql/data/pg_hba.conf \
    && echo "listen_addresses = '*'" >> /var/lib/pgsql/data/postgresql.conf

# Configure container user
RUN useradd -m vscode \
    && usermod -aG wheel vscode \
    && echo '%wheel ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

USER vscode
