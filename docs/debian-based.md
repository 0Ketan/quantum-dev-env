# 🐧 Debian-Based Linux Installation Guide

Manual installation guide for Ubuntu, Debian, Linux Mint, Pop!_OS, and Elementary OS.

> [!TIP]
> For automatic installation, use `./setup.sh` instead. This guide is for manual setup or troubleshooting.

---

## Prerequisites

- Debian-based Linux distribution
- Internet connection
- `sudo` access
- Terminal emulator

## Step 1: Update System

```bash
sudo apt update && sudo apt upgrade -y
```

## Step 2: Install System Packages

```bash
sudo apt install -y \
    python3 python3-pip python3-venv python3-dev \
    git build-essential gfortran cmake \
    libblas-dev liblapack-dev python3-tk curl
```

## Step 3: Install VS Code

### Option A: Via Microsoft Repository (recommended)

```bash
# Install dependencies
sudo apt install -y apt-transport-https wget gpg

# Add Microsoft GPG key
wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
    | gpg --dearmor \
    | sudo tee /usr/share/keyrings/packages.microsoft.gpg > /dev/null

# Add VS Code repository
echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/packages.microsoft.gpg] \
https://packages.microsoft.com/repos/code stable main" \
    | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null

# Install VS Code
sudo apt update
sudo apt install -y code
```

### Option B: Via Snap

```bash
sudo snap install code --classic
```

### Option C: Via Flatpak

```bash
flatpak install flathub com.visualstudio.code
```

## Step 4: Create Project Directory

```bash
mkdir -p ~/quantum
cd ~/quantum
```

## Step 5: Set Up Virtual Environment

```bash
python3 -m venv .venv
source .venv/bin/activate
```

> [!NOTE]
> On Ubuntu/Debian, use `python3` (not `python`) unless you've configured an alias.

## Step 6: Install Quantum Packages

```bash
pip install --upgrade pip

pip install \
    qiskit \
    qiskit-aer \
    qiskit-ibm-runtime \
    cirq \
    pennylane \
    numpy \
    matplotlib \
    scipy \
    jupyter \
    ipykernel
```

## Step 7: Register Jupyter Kernel

```bash
python -m ipykernel install --user \
    --name quantum-env \
    --display-name "Quantum Computing (Python)"
```

## Step 8: Configure VS Code

Create `.vscode/settings.json` in your quantum directory:

```bash
mkdir -p ~/quantum/.vscode
```

Copy [configs/vscode-settings.json](../configs/vscode-settings.json) to `~/quantum/.vscode/settings.json`.

Install recommended VS Code extensions:

```bash
code --install-extension ms-python.python
code --install-extension ms-toolsai.jupyter
code --install-extension ms-python.black-formatter
```

## Step 9: Add Shell Aliases

### Bash (~/.bashrc) — Default on Ubuntu/Debian

```bash
cat >> ~/.bashrc << 'EOF'

# >>> quantum-dev-env aliases >>>
alias qenv='source ~/quantum/.venv/bin/activate'
alias qcd='cd ~/quantum'
alias qtest='python ~/quantum/verify-setup.py'
# <<< quantum-dev-env aliases <<<
EOF
source ~/.bashrc
```

### Zsh (~/.zshrc)

```bash
cat >> ~/.zshrc << 'EOF'

# >>> quantum-dev-env aliases >>>
alias qenv='source ~/quantum/.venv/bin/activate'
alias qcd='cd ~/quantum'
alias qtest='python ~/quantum/verify-setup.py'
# <<< quantum-dev-env aliases <<<
EOF
source ~/.zshrc
```

## Step 10: Verify Installation

```bash
qenv
python verify-setup.py
```

---

## Ubuntu-Specific Notes

### Ubuntu 22.04 LTS

Python 3.10 is the default. This works fine with all quantum packages.

```bash
python3 --version  # Should show 3.10.x
```

### Ubuntu 24.04 LTS

Python 3.12 is the default. All packages should work. If you encounter issues:

```bash
# Install deadsnakes PPA for alternative Python versions
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt install python3.11 python3.11-venv python3.11-dev
python3.11 -m venv .venv
```

## Debian-Specific Notes

### Debian 12 (Bookworm)

Python 3.11 is the default — recommended version.

### Debian 11 (Bullseye)

Python 3.9 is the default. This works but you may encounter minor compatibility warnings. Consider upgrading to Debian 12.

## Linux Mint-Specific Notes

Linux Mint is Ubuntu-based, so all Ubuntu instructions apply. Mint 21.x uses Python 3.10, Mint 22.x uses Python 3.12.

---

## Troubleshooting

### "python3-venv" not found

```bash
# Install venv module explicitly
sudo apt install python3-venv

# For specific Python versions
sudo apt install python3.11-venv
```

### "externally-managed-environment" error (Ubuntu 24.04+)

```bash
# Always use a virtual environment (PEP 668)
python3 -m venv .venv
source .venv/bin/activate
pip install <package>  # Works fine inside venv
```

### Old pip version warnings

```bash
source .venv/bin/activate
pip install --upgrade pip setuptools wheel
```

### Build failures for compiled packages

```bash
# Ensure all build dependencies are installed
sudo apt install -y build-essential python3-dev \
    gfortran libblas-dev liblapack-dev cmake
```

### "No module named 'tkinter'"

```bash
sudo apt install python3-tk
```

See [troubleshooting.md](troubleshooting.md) for more common issues.
