#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

# This script runs after the container is created.

echo "Starting post-creation setup..."

# Update package lists and install pnpm globally using npm (comes with Node feature)
echo "Installing pnpm..."
sudo npm install -g pnpm

# Install Nx globally using pnpm
echo "Installing Nx..."
sudo pnpm install -g nx

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

# --- PNPM Global Setup Start ---
# Define the home directory for pnpm global installations
export PNPM_HOME="/home/codespace/.local/share/pnpm"
# Add the pnpm global bin directory to the PATH for this script execution
export PATH="$PNPM_HOME:$PATH"
# Ensure the PNPM_HOME directory exists before installing global packages
mkdir -p "$PNPM_HOME"
# --- PNPM Global Setup End ---

# Now install global packages using pnpm
# Need to explicitly use the pnpm path until the shell environment fully reloads
"$PNPM_HOME/pnpm" install -g @angular/cli nx

# Configure pnpm store location (good practice for containers)
"$PNPM_HOME/pnpm" config set store-dir ~/.local/share/pnpm/store

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
    # Use the pnpm path here too
    "$PNPM_HOME/pnpm" install
    cd ..
fi

echo 'postCreateCommand script finished.' 