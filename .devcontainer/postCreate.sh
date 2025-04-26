#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

# This script runs after the container is created.

echo "Starting post-creation setup..."

# Install Miniconda
echo "Installing Miniconda..."
sudo apt-get update && sudo apt-get install -y curl bzip2 libffi-dev libssl-dev --no-install-recommends
# Ensure target directory is clear before installing
sudo rm -rf /opt/conda 
curl -fsSL https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o /tmp/miniconda.sh \
    && sudo bash /tmp/miniconda.sh -b -p /opt/conda \
    && sudo rm /tmp/miniconda.sh \
    && sudo /opt/conda/bin/conda init bash \
    && sudo chown -R $(whoami) /opt/conda # Change ownership to current user
    # Add conda to PATH for current user's bashrc
    && echo ". /opt/conda/etc/profile.d/conda.sh" >> ~/.bashrc \
    && sudo /opt/conda/bin/conda config --system --set auto_activate_base false
# Make conda command available for the rest of the script
source /opt/conda/etc/profile.d/conda.sh

# Install pnpm globally using npm
echo "Installing pnpm..."
sudo npm install -g pnpm
# Setup pnpm environment (adds PNPM_HOME to ~/.bashrc and PATH)
echo "Setting up pnpm environment..."
pnpm setup
# Source .bashrc to make PNPM_HOME and updated PATH available now
source ~/.bashrc

# Install Nx globally using pnpm (no sudo)
echo "Installing Nx..."
pnpm install -g nx

# Install Go tools: GoNB kernel for Jupyter, Go Imports, GoPLS, and KinD
echo "Installing Go tools (GoNB, goimports, gopls, kind)..."
go install github.com/janpfeifer/gonb@latest && \
    go install golang.org/x/tools/cmd/goimports@latest && \
    go install golang.org/x/tools/gopls@latest && \
    go install sigs.k8s.io/kind@v0.23.0 && \
    $(go env GOPATH)/bin/gonb --install

# Install Playwright browsers
echo "Installing Playwright browsers..."
pnpm exec playwright install --with-deps

# Tidy backend Go modules if 'backend' dir exists
if [ -d "backend" ]; then
    echo "Found backend directory, running go mod tidy..."
    cd backend
    if command -v go &> /dev/null
    then
        go mod tidy
    else
      echo "WARNING: go command not found. Skipping go mod tidy."
    fi
    cd ..
fi

# Update apt cache and install Podman
echo "Installing Podman..."
sudo apt-get update && sudo apt-get install -y podman

echo "Post-creation setup complete."

# Now install global packages using pnpm
# Use pnpm directly now that PATH should be set
echo "Installing global pnpm packages (@angular/cli, nx)..."
pnpm install -g @angular/cli nx

# Configure pnpm store location (good practice for containers)
# pnpm config set store-dir ~/.local/share/pnpm/store

# Install JupyterLab using Conda (Assuming Conda is available from features)
if command -v conda &> /dev/null
then
    conda update -n base -c defaults conda
    conda install -y jupyterlab
else
    echo "WARNING: conda command not found. Skipping JupyterLab installation."
fi

# Install frontend dependencies if 'frontend' dir exists
if [ -d "frontend" ]; then
    echo "Found frontend directory, running pnpm install..."
    cd frontend
    # Use pnpm directly
    pnpm install
    cd ..
fi

echo 'postCreateCommand script finished.' 