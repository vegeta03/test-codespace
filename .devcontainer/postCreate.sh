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

# Install Miniconda via Homebrew (instead of direct download)
echo "Installing Miniconda via Homebrew..."
brew install --cask miniconda

# Initialize conda
echo "Initializing conda..."
eval "$(/home/linuxbrew/.linuxbrew/Caskroom/miniconda/base/bin/conda shell.bash hook)"
conda init bash
# Configure conda
conda config --set auto_activate_base false

# Install pnpm globally using npm
echo "Installing pnpm..."
sudo npm install -g pnpm
# Setup pnpm environment (adds PNPM_HOME to ~/.bashrc and PATH)
echo "Setting up pnpm environment..."
pnpm setup
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

# Install Playwright - globally via pnpm for now, but browsers via Homebrew
echo "Installing Playwright..."
pnpm install -g playwright
# Install browsers via Homebrew for better performance
brew install --cask chromium firefox

# Still need to run Playwright install for WebKit and other dependencies
echo "Installing remaining Playwright dependencies..."
playwright install --with-deps webkit

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

# Install JupyterLab using Homebrew (instead of Conda)
echo "Installing JupyterLab via Homebrew..."
brew install jupyterlab

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
echo "NPM Version: $(npm -v)"

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
echo "Conda Version: $(conda --version 2>/dev/null || echo 'Not installed')"
echo "JupyterLab Version: $(jupyter-lab --version 2>/dev/null || echo 'Not installed')"

# Playwright
echo "Playwright Version: $(npx playwright --version 2>/dev/null || echo 'Not installed')"

# Homebrew
echo "Homebrew Version: $(brew --version | head -n 1)"

echo "==================================================================="
echo "postCreateCommand script finished." 