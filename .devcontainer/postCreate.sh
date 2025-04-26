#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status.

# Update package lists and install essential packages
sudo apt-get update && sudo apt-get install -y --no-install-recommends

# Install pnpm using npm
npm install -g pnpm

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

# Install Go tools needed by GoNB (Assuming Go is available from features)
if command -v go &> /dev/null
then
    go install golang.org/x/tools/cmd/goimports@latest
    go install golang.org/x/tools/gopls@latest
    # Install GoNB kernel
    go install github.com/janpfeifer/gonb@latest
    # Register GoNB kernel with Jupyter (requires Go bin in PATH, feature usually handles this)
    gonb --install
else
    echo "WARNING: go command not found. Skipping Go tool and GoNB installation."
fi

# Install Playwright browsers system-wide (Assuming Node/npx is available)
if command -v npx &> /dev/null
then
    npx playwright install --with-deps
else
    echo "WARNING: npx command not found. Skipping Playwright browser installation."
fi

# Install frontend dependencies if 'frontend' dir exists
if [ -d "frontend" ]; then
    echo "Found frontend directory, running pnpm install..."
    cd frontend
    # Use the pnpm path here too
    "$PNPM_HOME/pnpm" install
    cd ..
fi

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

echo 'postCreateCommand script finished.' 