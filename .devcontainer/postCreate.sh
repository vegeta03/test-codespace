#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

# This script runs after the container is created.

echo "Starting post-creation setup..."

# Add Homebrew to PATH for this script
export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"

# Update Homebrew and install basic tools
echo "Updating Homebrew..."
brew update
brew install wget curl

# Install Miniconda directly (not via Homebrew cask which is macOS-only)
echo "Installing Miniconda directly..."
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh
bash /tmp/miniconda.sh -b -p $HOME/miniconda
rm /tmp/miniconda.sh

# Initialize conda
echo "Initializing conda..."
eval "$($HOME/miniconda/bin/conda shell.bash hook)"
$HOME/miniconda/bin/conda init bash
# Configure conda
$HOME/miniconda/bin/conda config --set auto_activate_base false

# Install pnpm using the official install script instead of npm
echo "Installing pnpm..."
curl -fsSL https://get.pnpm.io/install.sh | bash -
# Setup pnpm environment (adds PNPM_HOME to ~/.bashrc and PATH)
echo "Setting up pnpm environment..."
# Source the bashrc to get pnpm in the current session
source ~/.bashrc
# Explicitly set PNPM_HOME and update PATH for the current session
export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"
echo "PNPM_HOME is set to: $PNPM_HOME"
echo "Updated PATH: $PATH"

# Configure pnpm to allow building all dependencies (avoids interactive approval)
# This was added in pnpm v10.9.0 and is useful for CI/CD environments
echo "Configuring pnpm to allow all builds..."
pnpm config set dangerouslyAllowAllBuilds true

# Install Nx globally using pnpm (no sudo)
echo "Installing Nx..."
pnpm install -g nx

# Install Go tools via Homebrew and Go install
echo "Installing Go tools via Homebrew and Go install..."
brew install gopls kind

# Install GoNB via Go install (not available in Homebrew)
echo "Installing GoNB via Go install..."
go install github.com/janpfeifer/gonb@latest
go install golang.org/x/tools/cmd/goimports@latest
$(go env GOPATH)/bin/gonb --install

# Install Playwright - globally via pnpm
echo "Installing Playwright..."
pnpm install -g playwright

# Install Playwright browsers using Playwright's own mechanism
echo "Installing Playwright browsers..."
# Install required dependencies first
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libatspi2.0-0 \
    libcairo2 \
    libcups2 \
    libdbus-1-3 \
    libdrm2 \
    libgbm1 \
    libglib2.0-0 \
    libnspr4 \
    libnss3 \
    libpango-1.0-0 \
    libx11-6 \
    libxcb1 \
    libxcomposite1 \
    libxdamage1 \
    libxext6 \
    libxfixes3 \
    libxkbcommon0 \
    libxrandr2 \
    xvfb \
    fonts-noto-color-emoji \
    ttf-ubuntu-font-family \
    fonts-liberation \
    libvpx6 \
    libevent-2.1-7

# Use Playwright's installer with system dependencies directly (it's in PATH)
playwright install --with-deps chromium firefox webkit

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

# Install Podman via Homebrew (newer version)
echo "Installing Podman via Homebrew..."
brew install podman
# Initialize Podman
podman machine init || echo "WARNING: Failed to initialize Podman machine. Continuing anyway..."
podman machine start || echo "WARNING: Failed to start Podman machine. Continuing anyway..."

echo "Post-creation setup continues..."

# Now install global packages using pnpm
# Use pnpm directly now that PATH should be set
echo "Installing global pnpm packages (@angular/cli, nx)..."
pnpm install -g @angular/cli nx

# Configure pnpm store location (good practice for containers)
# pnpm config set store-dir ~/.local/share/pnpm/store

# Install JupyterLab via pip (more reliable cross-platform than Homebrew for Python packages)
echo "Installing JupyterLab via pip..."
$HOME/miniconda/bin/pip install jupyterlab

# Install frontend dependencies if 'frontend' dir exists
if [ -d "frontend" ]; then
    echo "Found frontend directory, running pnpm install..."
    cd frontend
    # Use pnpm directly
    pnpm install
    cd ..
fi

# Display versions of all installed components
echo "==================================================================="
echo "INSTALLED COMPONENTS VERSIONS"
echo "==================================================================="

# Node and npm
echo "Node Version: $(node -v)"
echo "NPM Version: $(pnpm -v)"

# pnpm and Nx
echo "PNPM Version: $(pnpm -v)"
echo "Nx Version: $(nx --version 2>/dev/null || echo 'Not installed')"

# Angular CLI
echo "Angular CLI Version: $(ng version --version 2>/dev/null || echo 'Not installed')"

# Go and Go tools
echo "Go Version: $(go version)"
echo "GoNB Version: $(go list -m github.com/janpfeifer/gonb 2>/dev/null || echo 'Not installed')"
echo "GoImports Version: $(goimports --version 2>/dev/null || echo 'Not available')"
echo "GoPLS Version: $(gopls version 2>/dev/null || echo 'Not available')"
echo "Kind Version: $(kind version)"

# Docker and Podman
echo "Docker Version: $(docker --version 2>/dev/null || echo 'Not installed')"
echo "Podman Version: $(podman --version 2>/dev/null || echo 'Not installed')"

# Kubernetes tools
echo "Kubectl Version: $(kubectl version --client 2>/dev/null | grep Client || echo 'Not installed')"
echo "Helm Version: $(helm version --short 2>/dev/null || echo 'Not installed')"
echo "Kustomize Version: $(kustomize version --short 2>/dev/null || echo 'Not installed')"

# Java
echo "Java Version: $(java -version 2>&1 | head -n 1)"
echo "Maven Version: $(mvn --version 2>/dev/null | head -n 1 || echo 'Not installed')"
echo "Gradle Version: $(gradle --version 2>/dev/null | head -n 3 | tail -n 1 || echo 'Not installed')"

# Python and JupyterLab
echo "Python Version: $(python --version 2>&1)"
echo "Conda Version: $($HOME/miniconda/bin/conda --version 2>/dev/null || echo 'Not installed')"
echo "JupyterLab Version: $($HOME/miniconda/bin/jupyter-lab --version 2>/dev/null || echo 'Not installed')"

# Playwright
echo "Playwright Version: $(playwright --version 2>/dev/null || echo 'Not installed')"

# Homebrew
echo "Homebrew Version: $(brew --version | head -n 1)"

echo "==================================================================="
echo "postCreateCommand script finished." 