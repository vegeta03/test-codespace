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

# --- Install Core Tools (Homebrew) ---
echo "Updating Homebrew and installing basic tools (wget, curl, kustomize, gradle, kubectl - verbose)..."
brew update
# Removed terraform - will install via APT
brew install -v wget curl kustomize gradle kubectl

echo "Verifying kubectl installation..."
# Use command -v and exit if not found
if ! command -v kubectl &> /dev/null; then
    echo "ERROR: kubectl command not found in PATH immediately after brew install."
    echo "PATH was: $PATH"
    exit 1
fi
echo "kubectl found at: $(command -v kubectl)"

# --- Install Terraform via APT ---
echo "Ensuring prerequisites for Terraform APT repo..."
sudo apt-get update && sudo apt-get install -y gnupg software-properties-common curl
echo "Adding HashiCorp GPG key..."
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "Adding HashiCorp APT repository..."
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
echo "Installing Terraform via apt..."
sudo apt-get update && sudo apt-get install -y terraform

echo "Verifying Terraform installation..."
if ! command -v terraform &> /dev/null; then
    echo "ERROR: terraform command not found in PATH immediately after apt install."
    echo "PATH was: $PATH"
    exit 1
fi
echo "terraform found at: $(command -v terraform)"


# --- Install pnpm --- 
echo "Installing pnpm..."
curl -fsSL https://get.pnpm.io/install.sh | bash -
# Explicitly set PNPM_HOME and update PATH for the current session
export PNPM_HOME="$HOME/.local/share/pnpm"
export PATH="$PNPM_HOME:$PATH"
echo "PNPM_HOME is set to: $PNPM_HOME"
echo "Updated PATH for pnpm: $PATH"
# Verify pnpm global bin location
echo "pnpm expected global bin: $PNPM_HOME"
echo "pnpm actual global bin: $(pnpm -g bin || echo 'Failed to get pnpm global bin')"

echo "Configuring pnpm..."
pnpm config set dangerouslyAllowAllBuilds true

# --- Install Global Node.js Packages ---
echo "Installing global pnpm packages (@angular/cli, nx, playwright)..."
# Moved this earlier and added playwright here
pnpm install -g @angular/cli nx playwright

echo "Verifying Angular CLI (ng) installation..."
# Use command -v and exit if not found
if ! command -v ng &> /dev/null; then
    echo "ERROR: ng command not found in PATH immediately after pnpm install -g."
    echo "PATH was: $PATH"
    ls -la $PNPM_HOME || echo "Could not list $PNPM_HOME"
    exit 1
fi
echo "ng found at: $(command -v ng)"

# --- Install Miniconda & Jupyter ---
echo "Installing Miniconda directly..."
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh
bash /tmp/miniconda.sh -b -p $HOME/miniconda
rm /tmp/miniconda.sh

echo "Initializing conda (temporarily disabled PATH modifications for debugging)..."
# TEMPORARILY COMMENTED OUT FOR DEBUGGING PATH ISSUES
# eval "$($HOME/miniconda/bin/conda shell.bash hook)"
# $HOME/miniconda/bin/conda init bash
echo "Skipping conda shell hook and init for PATH debugging."
$HOME/miniconda/bin/conda config --set auto_activate_base false

echo "Installing JupyterLab and Notebook via pip..."
# Use full path to pip and install notebook as well
$HOME/miniconda/bin/pip install jupyterlab notebook || echo "WARNING: Failed to install JupyterLab/Notebook."

# --- Install Go Tools ---
echo "Installing Go tools (gopls, kind via brew; GoNB, goimports via go install)..."
# Use verbose brew install here too for consistency
brew install -v gopls kind
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
echo "Installing Podman via Homebrew (verbose)..."
brew install -v podman
echo "INFO: Podman installed, manual initialization might be needed (podman machine init/start)."


# --- Final Version Checks --- 
echo "==================================================================="
echo "FINAL PATH BEFORE VERSION CHECKS: $PATH"
echo "==================================================================="
echo "INSTALLED COMPONENTS VERSIONS"
echo "==================================================================="

# Node and pnpm (as primary JS package manager)
echo "Node Version: $(node -v)"
echo "pnpm Version: $(pnpm -v)"

# Nx
echo "Nx Version: $(nx --version 2>/dev/null || echo 'Nx: Not found')"

# Angular CLI - Enhanced Check
echo "--- Checking Angular CLI (ng) ---"
if command -v ng &> /dev/null; then
    echo "Attempting to get ng version..."
    NG_VERSION_OUTPUT=$(ng --version 2>&1) # Capture stdout and stderr
    NG_EXIT_CODE=$?
    echo "Raw 'ng --version' output: $NG_VERSION_OUTPUT"
    echo "ng exit code: $NG_EXIT_CODE"
    if [ $NG_EXIT_CODE -eq 0 ]; then
        # If command succeeded, use its output directly as the version
        echo "Angular CLI Version: $NG_VERSION_OUTPUT"
    else
        echo "Angular CLI Version: Installed but 'ng --version' failed (Code: $NG_EXIT_CODE)"
    fi
else
    echo "ng command not found in final PATH check."
    echo "Angular CLI Version: Not installed"
fi
echo "--- Finished checking ng ---"


# Go and Go tools
echo "Go Version: $(go version)"
echo "GoNB Version: $(command -v gonb &> /dev/null && echo 'Installed' || echo 'GoNB: Not installed')"
echo "GoImports Version: $(command -v goimports &> /dev/null && echo 'Installed' || echo 'GoImports: Not installed')"
echo "GoPLS Version: $(gopls version 2>/dev/null || echo 'GoPLS: Not installed')"
echo "Kind Version: $(kind version 2>/dev/null || echo 'Kind: Not installed')"


# Docker and Podman
echo "Docker Version: $(docker --version 2>/dev/null || echo 'Docker: Not installed')"
echo "Podman Version: $(podman --version 2>/dev/null || echo 'Podman: Not installed')"

# Kubernetes tools - Enhanced Check
echo "--- Checking Kubectl ---"
if command -v kubectl &> /dev/null; then
    echo "Attempting to get kubectl client version..."
    # Use 'kubectl version --client' without '--short'
    KUBECTL_VERSION_OUTPUT=$(kubectl version --client 2>&1)
    KUBECTL_EXIT_CODE=$?
    echo "Raw 'kubectl version --client' output: $KUBECTL_VERSION_OUTPUT"
    echo "kubectl exit code: $KUBECTL_EXIT_CODE"
    if [ $KUBECTL_EXIT_CODE -eq 0 ]; then
        # If command succeeded, use its output
        echo "Kubectl Version: $KUBECTL_VERSION_OUTPUT"
    else
        echo "Kubectl Version: Installed but 'kubectl version --client' failed (Code: $KUBECTL_EXIT_CODE)"
    fi
else
    echo "kubectl command not found in final PATH check."
    echo "Kubectl Version: Not installed"
fi
echo "--- Finished checking kubectl ---"

# Helm, Kustomize
echo "Helm Version: $(helm version --short 2>/dev/null || echo 'Helm: Not installed')"
echo "Kustomize Version: $(kustomize version --short 2>/dev/null || echo 'Kustomize: Not installed')"

# Java
echo "Java Version: $(java -version 2>&1 | head -n 1)"
echo "Maven Version: $(mvn --version 2>/dev/null | head -n 1 || echo 'Maven: Not installed')"
echo "Gradle Version: $(gradle --version | grep Gradle 2>/dev/null || echo 'Gradle: Not installed')"

# Python and JupyterLab
echo "Python Version: $($HOME/miniconda/bin/python --version 2>&1)"
echo "Conda Version: $($HOME/miniconda/bin/conda --version 2>/dev/null || echo 'Conda: Not installed')"
echo "JupyterLab Version: $($HOME/miniconda/bin/jupyter-lab --version 2>/dev/null || echo 'JupyterLab: Not installed')"
echo "Jupyter Notebook Version: $($HOME/miniconda/bin/jupyter-notebook --version 2>/dev/null || echo 'Jupyter Notebook: Not installed')"

# Playwright
echo "Playwright Version: $(playwright --version 2>/dev/null || echo 'Playwright: Not installed')"

# Terraform - Check uses standard version command
echo "--- Checking Terraform ---"
if command -v terraform &> /dev/null; then
    echo "Attempting to get terraform version..."
    # Use 'terraform version' or 'terraform --version' which usually includes the version on the first line
    TERRAFORM_VERSION_OUTPUT=$(terraform version 2>&1 | head -n 1)
    TERRAFORM_EXIT_CODE=$?
    echo "Raw 'terraform version' output (first line): $TERRAFORM_VERSION_OUTPUT"
    echo "terraform exit code: $TERRAFORM_EXIT_CODE"
    if [ $TERRAFORM_EXIT_CODE -eq 0 ]; then
        # If command succeeded, use its output
        echo "Terraform Version: $TERRAFORM_VERSION_OUTPUT"
    else
        echo "Terraform Version: Installed but 'terraform version' failed (Code: $TERRAFORM_EXIT_CODE)"
    fi
else
    echo "terraform command not found in final PATH check."
    echo "Terraform Version: Not installed"
fi
echo "--- Finished checking Terraform ---"


# Rust
echo "Rustc Version: $(rustc --version 2>/dev/null || echo 'Rustc: Not installed')"
echo "Cargo Version: $(cargo --version 2>/dev/null || echo 'Cargo: Not installed')"
echo "Rustup Version: $(rustup --version 2>/dev/null || echo 'Rustup: Not installed')"

# Homebrew
echo "Homebrew Version: $(brew --version | head -n 1)"

echo "==================================================================="
echo "postCreateCommand script finished." 