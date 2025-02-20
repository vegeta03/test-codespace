#!/bin/bash
set -eo pipefail

# Start PostgreSQL
echo "Starting PostgreSQL..."
sudo -u postgres pg_ctl start -D $PGDATA -l $PGDATA/log/postgres.log -w -t 60

# Verify PostgreSQL status
echo "Verifying PostgreSQL status..."
sudo -u postgres pg_isready -d postgres -U postgres

# Create Kind cluster
echo "Creating Kind cluster..."
kind create cluster
