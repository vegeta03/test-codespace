#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

# This script runs after the container is created.

echo "Starting post-creation setup..."

# --- Setup Core Paths ---
# Add Homebrew to PATH for this script
export PATH="/home/linuxbrew/.linuxbrew/bin:$PATH"
# Assuming Go feature ran and set GOPATH, ensure GOPATH/bin is in PATH
export PATH=$(go env GOPATH)/bin:$PATH
# Rust feature adds cargo bin to PATH automatically, but ensure ~/.cargo/bin is considered
export PATH="$HOME/.cargo/bin:$PATH"

# --- Install Core Tools (pnpm, Homebrew packages) ---
echo "Updating Homebrew and installing basic tools..."
brew update
brew install wget curl kustomize gradle terraform kubectl # Added kubectl

echo "Installing pnpm..."
curl -fsSL https://get.pnpm.io/install.sh | bash -
# Source the bashrc to get pnpm in the current session
source ~/.bashrc
# Explicitly set PNPM_HOME and update PATH for the current session
export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"
echo "PNPM_HOME is set to: $PNPM_HOME"
echo "Updated PATH: $PATH"

echo "Configuring pnpm..."
pnpm config set dangerouslyAllowAllBuilds true

# --- Install Global Node.js Packages ---
echo "Installing global pnpm packages (@angular/cli, nx, playwright)..."
# Moved this earlier and added playwright here
pnpm install -g @angular/cli nx playwright

# --- Install Miniconda & Jupyter ---
echo "Installing Miniconda directly..."
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh
bash /tmp/miniconda.sh -b -p $HOME/miniconda
rm /tmp/miniconda.sh

echo "Initializing conda..."
eval "$($HOME/miniconda/bin/conda shell.bash hook)"
$HOME/miniconda/bin/conda init bash
$HOME/miniconda/bin/conda config --set auto_activate_base false

echo "Installing JupyterLab and Notebook via pip..."
# Use full path to pip and install notebook as well
$HOME/miniconda/bin/pip install jupyterlab notebook || echo "WARNING: Failed to install JupyterLab/Notebook."

# --- Install Go Tools ---
echo "Installing Go tools (gopls, kind via brew; GoNB, goimports via go install)..."
brew install gopls kind # Already installed gopls? Brew will handle it.
go install github.com/janpfeifer/gonb@latest || echo "WARNING: Failed to install GoNB."
go install golang.org/x/tools/cmd/goimports@latest || echo "WARNING: Failed to install goimports."
# Run GoNB install only if the binary exists
if command -v gonb &> /dev/null; then
    gonb --install || echo "WARNING: gonb --install failed."
else
    echo "WARNING: gonb command not found, skipping gonb --install."
fi

# --- Install Playwright Browsers ---
echo "Installing Playwright system dependencies..."
sudo apt-get update
sudo apt-get install -y --no-install-recommends \
    libasound2 libatk-bridge2.0-0 libatk1.0-0 libatspi2.0-0 libcairo2 \
    libcups2 libdbus-1-3 libdrm2 libgbm1 libglib2.0-0 libnspr4 libnss3 \
    libpango-1.0-0 libx11-6 libxcb1 libxcomposite1 libxdamage1 libxext6 \
    libxfixes3 libxkbcommon0 libxrandr2 xvfb fonts-noto-color-emoji \
    ttf-ubuntu-font-family fonts-liberation libvpx6 libevent-2.1-7 || echo "WARNING: Failed to install Playwright apt dependencies."

echo "Installing Playwright browsers..."
# Use Playwright's installer directly (it's in PATH from global install)
playwright install --with-deps chromium firefox webkit || echo "WARNING: playwright install failed."

# --- Project Specific Setups ---
# Tidy backend Go modules if 'backend' dir exists
if [ -d "backend" ]; then
    echo "Found backend directory, running go mod tidy..."
    cd backend
    if command -v go &> /dev/null; then
        go mod tidy || echo "WARNING: go mod tidy failed in backend."
    else
        echo "WARNING: go command not found. Skipping go mod tidy in backend."
    fi
    cd ..
fi

# Install frontend dependencies if 'frontend' dir exists
if [ -d "frontend" ]; then
    echo "Found frontend directory, running pnpm install..."
    cd frontend
    pnpm install || echo "WARNING: pnpm install failed in frontend."
    cd ..
fi

# --- Install Podman ---
# Note: Consider if Docker-in-Docker feature is sufficient, Podman might conflict or be redundant
echo "Installing Podman via Homebrew..."
brew install podman
# Initialize Podman (might require user interaction or specific setup)
# podman machine init || echo "WARNING: Failed to initialize Podman machine."
# podman machine start || echo "WARNING: Failed to start Podman machine."
echo "INFO: Podman installed, manual initialization might be needed (podman machine init/start)."


# --- Final Version Checks ---
echo "==================================================================="
echo "INSTALLED COMPONENTS VERSIONS"
echo "==================================================================="

# Node and pnpm (as primary JS package manager)
echo "Node Version: $(node -v)"
echo "pnpm Version: $(pnpm -v)"

# Nx
echo "Nx Version: $(nx --version 2>/dev/null || echo 'Not installed')"

# Angular CLI
echo "Angular CLI Version: $(ng --version | grep 'Angular CLI' 2>/dev/null || echo 'Not installed')"

# Go and Go tools
echo "Go Version: $(go version)"
echo "GoNB Version: $(command -v gonb &> /dev/null && echo 'Installed' || echo 'Not installed')"
echo "GoImports Version: $(command -v goimports &> /dev/null && echo 'Installed' || echo 'Not installed')"
echo "GoPLS Version: $(gopls version 2>/dev/null || echo 'Not installed')" # gopls has version flag
echo "Kind Version: $(kind version 2>/dev/null || echo 'Not installed')"

# Docker and Podman
echo "Docker Version: $(docker --version 2>/dev/null || echo 'Not installed')"
echo "Podman Version: $(podman --version 2>/dev/null || echo 'Not installed')"

# Kubernetes tools
echo "Kubectl Version: $(kubectl version --client --short 2>/dev/null || echo 'Not installed')" # Use --short
echo "Helm Version: $(helm version --short 2>/dev/null || echo 'Not installed')"
echo "Kustomize Version: $(kustomize version --short 2>/dev/null || echo 'Not installed')" # Should be installed now

# Java
echo "Java Version: $(java -version 2>&1 | head -n 1)"
echo "Maven Version: $(mvn --version 2>/dev/null | head -n 1 || echo 'Not installed')"
echo "Gradle Version: $(gradle --version | grep Gradle 2>/dev/null || echo 'Not installed')" # Should be installed now

# Python and JupyterLab
echo "Python Version: $($HOME/miniconda/bin/python --version 2>&1)" # Use conda python
echo "Conda Version: $($HOME/miniconda/bin/conda --version 2>/dev/null || echo 'Not installed')"
echo "JupyterLab Version: $($HOME/miniconda/bin/jupyter-lab --version 2>/dev/null || echo 'Not installed')"
echo "Jupyter Notebook Version: $($HOME/miniconda/bin/jupyter-notebook --version 2>/dev/null || echo 'Not installed')"

# Playwright
echo "Playwright Version: $(playwright --version 2>/dev/null || echo 'Not installed')"

# Terraform
echo "Terraform Version: $(terraform --version | head -n 1 2>/dev/null || echo 'Not installed')"

# Rust
echo "Rustc Version: $(rustc --version 2>/dev/null || echo 'Not installed')"
echo "Cargo Version: $(cargo --version 2>/dev/null || echo 'Not installed')"
echo "Rustup Version: $(rustup --version 2>/dev/null || echo 'Not installed')"

# Homebrew
echo "Homebrew Version: $(brew --version | head -n 1)"

echo "==================================================================="
echo "postCreateCommand script finished." 