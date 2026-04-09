# 🐧 Arch-Based Linux Installation Guide

Manual installation guide for Arch Linux, Manjaro, CachyOS, Garuda, and EndeavourOS.

> [!TIP]
> For automatic installation, use `./setup.sh` instead. This guide is for manual setup or troubleshooting.

---

## Prerequisites

- Arch-based Linux distribution
- Internet connection
- `sudo` access
- Terminal emulator

## Step 1: Update System

```bash
sudo pacman -Syu
```

## Step 2: Install System Packages

```bash
sudo pacman -S --needed \
    python python-pip python-virtualenv \
    git base-devel gcc gcc-fortran cmake \
    blas lapack tk
```

## Step 3: Install VS Code

### Option A: From AUR (recommended)

If you have an AUR helper (yay, paru):

```bash
# Using yay
yay -S visual-studio-code-bin

# Using paru
paru -S visual-studio-code-bin
```

### Option B: Code OSS from official repos

```bash
sudo pacman -S code
```

### Option C: Flatpak

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
python -m venv .venv
source .venv/bin/activate
```

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

### Bash (~/.bashrc)

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

### Fish (~/.config/fish/conf.d/quantum.fish)

```fish
alias qenv='source ~/quantum/.venv/bin/activate.fish'
alias qcd='cd ~/quantum'
alias qtest='python ~/quantum/verify-setup.py'
```

## Step 10: Verify Installation

```bash
qenv
python verify-setup.py
```

---

## CachyOS-Specific Notes

CachyOS uses performance-optimized packages. The setup is identical to Arch, but you may benefit from:

```bash
# CachyOS-optimized Python (if available in CachyOS repos)
sudo pacman -S python

# CachyOS has march-optimized packages that may improve
# numerical computation performance for numpy/scipy
```

## Garuda-Specific Notes

Garuda uses `garuda-update` as its recommended update command:

```bash
garuda-update  # Instead of pacman -Syu
```

If using Garuda's Fish shell by default, use the Fish aliases above.

## Manjaro-Specific Notes

Manjaro may have slightly older package versions in its stable branch. If you encounter version issues:

```bash
# Check Python version
python --version

# If below 3.8, switch to testing branch or use pyenv
# sudo pacman-mirrors --api --set-branch testing
# sudo pacman -Syyuu
```

---

## Troubleshooting

### "error: target not found" during pacman install

```bash
# Refresh package databases
sudo pacman -Sy
# Retry the install
```

### Python version too old

```bash
# Install pyenv for managing Python versions
yay -S pyenv
pyenv install 3.11
pyenv local 3.11
```

### "externally-managed-environment" error

This happens on newer Arch with PEP 668. The virtual environment approach avoids this:

```bash
# Always use a venv (which our setup does)
python -m venv .venv
source .venv/bin/activate
pip install <package>  # Works fine inside venv
```

### Build failures for qiskit-aer

```bash
# Ensure build tools are installed
sudo pacman -S base-devel cmake gcc gcc-fortran blas lapack
```

See [troubleshooting.md](troubleshooting.md) for more common issues.
