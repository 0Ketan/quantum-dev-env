# 🔧 Troubleshooting Guide

Common issues and solutions for the quantum-dev-env setup.

---

## Table of Contents

- [Command Not Found](#command-not-found)
- [Python Version Issues](#python-version-issues)
- [Virtual Environment Problems](#virtual-environment-problems)
- [Import Errors](#import-errors)
- [VS Code Issues](#vs-code-issues)
- [Shell Alias Not Working](#shell-alias-not-working)
- [Permission Errors](#permission-errors)
- [Build/Compilation Errors](#buildcompilation-errors)
- [Jupyter Issues](#jupyter-issues)
- [Platform-Specific Issues](#platform-specific-issues)
- [Network Issues](#network-issues)

---

## Command Not Found

### `qenv: command not found`

**Cause:** Shell aliases haven't been loaded yet.

**Solution:**

```bash
# Reload your shell configuration
source ~/.bashrc    # For Bash
source ~/.zshrc     # For Zsh
# Or restart your terminal
```

If aliases were never added:

```bash
# Add manually
echo "alias qenv='source ~/quantum/.venv/bin/activate'" >> ~/.bashrc
source ~/.bashrc
```

### `python: command not found`

**Cause:** Python isn't installed or not in PATH.

**Solution:**

```bash
# Check if python3 exists instead
python3 --version

# Arch Linux
sudo pacman -S python

# Ubuntu/Debian
sudo apt install python3

# Create symlink if needed
sudo ln -s /usr/bin/python3 /usr/bin/python
```

### `pip: command not found`

**Solution:**

```bash
# Use python -m pip instead
python3 -m pip --version

# Install pip
# Arch
sudo pacman -S python-pip

# Ubuntu/Debian
sudo apt install python3-pip
```

---

## Python Version Issues

### Python version is below 3.8

**Solution:**

```bash
# Check current version
python3 --version

# Arch: Python is usually up-to-date
sudo pacman -S python

# Ubuntu: Use deadsnakes PPA
sudo add-apt-repository ppa:deadsnakes/ppa
sudo apt update
sudo apt install python3.11 python3.11-venv python3.11-dev

# Use pyenv (any platform)
curl https://pyenv.run | bash
pyenv install 3.11
pyenv local 3.11
```

### Multiple Python versions causing confusion

```bash
# Check which Python is being used
which python3
python3 --version

# Inside venv, check explicitly
which python
python --version
```

---

## Virtual Environment Problems

### "externally-managed-environment" error (PEP 668)

**Cause:** Modern distros prevent pip installing to system Python.

**Solution:** Always use a virtual environment (which our setup does):

```bash
python3 -m venv ~/quantum/.venv
source ~/quantum/.venv/bin/activate
pip install <package>  # Works fine inside venv
```

### Cannot create virtual environment

```bash
# Install venv module
# Ubuntu/Debian
sudo apt install python3-venv

# For specific Python versions
sudo apt install python3.11-venv

# Arch
sudo pacman -S python-virtualenv
```

### Virtual environment won't activate

```bash
# Check the activate script exists
ls ~/quantum/.venv/bin/activate

# If missing, recreate the venv
rm -rf ~/quantum/.venv
python3 -m venv ~/quantum/.venv
source ~/quantum/.venv/bin/activate
```

### "No module named venv"

```bash
# Ubuntu/Debian
sudo apt install python3-venv

# The venv module should be included with Python on Arch
sudo pacman -S python
```

---

## Import Errors

### `ModuleNotFoundError: No module named 'qiskit'`

**Cause:** Package not installed, or not in the active virtual environment.

**Solution:**

```bash
# Make sure venv is active
source ~/quantum/.venv/bin/activate

# Verify the package is installed
pip list | grep qiskit

# Reinstall if missing
pip install qiskit qiskit-aer qiskit-ibm-runtime
```

### `ImportError: cannot import name 'Aer' from 'qiskit'`

**Cause:** Qiskit 1.0+ removed `Aer` from the main package. Use `qiskit_aer` instead.

**Solution:**

```python
# Old (deprecated):
# from qiskit import Aer

# New (correct):
from qiskit_aer import AerSimulator
simulator = AerSimulator()
```

### `ModuleNotFoundError: No module named 'cirq'`

```bash
source ~/quantum/.venv/bin/activate
pip install cirq
```

### Version conflicts between packages

```bash
# Check for conflicts
pip check

# Upgrade all packages
pip install --upgrade qiskit qiskit-aer cirq pennylane

# Nuclear option: recreate venv
rm -rf ~/quantum/.venv
python3 -m venv ~/quantum/.venv
source ~/quantum/.venv/bin/activate
pip install qiskit qiskit-aer qiskit-ibm-runtime cirq pennylane \
    numpy matplotlib scipy jupyter ipykernel
```

---

## VS Code Issues

### VS Code doesn't find the Python interpreter

1. Open Command Palette (`Ctrl+Shift+P`)
2. Type `Python: Select Interpreter`
3. Choose: `~/quantum/.venv/bin/python`

Or set it manually in `.vscode/settings.json`:

```json
{
    "python.defaultInterpreterPath": "~/quantum/.venv/bin/python"
}
```

### Jupyter kernel not showing in VS Code

```bash
# Register the kernel
source ~/quantum/.venv/bin/activate
python -m ipykernel install --user \
    --name quantum-env \
    --display-name "Quantum Computing (Python)"

# Restart VS Code
```

### VS Code terminal doesn't activate venv

Add to `.vscode/settings.json`:

```json
{
    "python.terminal.activateEnvironment": true,
    "python.terminal.activateEnvInCurrentTerminal": true
}
```

---

## Shell Alias Not Working

### Aliases disappear after restart

**Cause:** Aliases were added to the wrong shell config file.

```bash
# Check your default shell
echo $SHELL

# Make sure aliases are in the right file:
# /bin/bash  → ~/.bashrc
# /bin/zsh   → ~/.zshrc
# /bin/fish  → ~/.config/fish/conf.d/quantum.fish
```

### Aliases not found in new terminal tabs

```bash
# Some terminals source .bash_profile instead of .bashrc
# Add to .bash_profile if needed:
echo 'source ~/.bashrc' >> ~/.bash_profile
```

---

## Permission Errors

### "Permission denied" during installation

```bash
# Don't use sudo with pip inside a venv!
# Activate venv first:
source ~/quantum/.venv/bin/activate
pip install <package>

# For system packages, use sudo:
sudo pacman -S python    # Arch
sudo apt install python3  # Debian
```

### Cannot write to ~/quantum

```bash
# Check directory ownership
ls -la ~/quantum

# Fix ownership
sudo chown -R $USER:$USER ~/quantum
```

---

## Build/Compilation Errors

### Failed building wheel for qiskit-aer

```bash
# Install build dependencies
# Arch
sudo pacman -S base-devel cmake gcc gcc-fortran blas lapack

# Ubuntu/Debian
sudo apt install build-essential cmake gfortran \
    libblas-dev liblapack-dev python3-dev

# Then retry
pip install qiskit-aer
```

### "error: Microsoft Visual C++ 14.0 is required" (Windows)

```powershell
# Install Visual Studio Build Tools
winget install Microsoft.VisualStudio.2022.BuildTools

# Or download from:
# https://visualstudio.microsoft.com/visual-cpp-build-tools/
# Select "Desktop development with C++"
```

---

## Jupyter Issues

### Jupyter notebook won't start

```bash
source ~/quantum/.venv/bin/activate
pip install --upgrade jupyter notebook

# Try with explicit path
python -m jupyter notebook
```

### Wrong kernel in Jupyter

```bash
# List available kernels
jupyter kernelspec list

# Remove old kernel
jupyter kernelspec remove <old-kernel-name>

# Re-register
python -m ipykernel install --user \
    --name quantum-env \
    --display-name "Quantum Computing (Python)"
```

### "No module named jupyter_core"

```bash
source ~/quantum/.venv/bin/activate
pip install jupyter notebook ipykernel
```

---

## Platform-Specific Issues

### Arch: Key import errors during pacman -Syu

```bash
sudo pacman-key --init
sudo pacman-key --populate archlinux
sudo pacman -Sy archlinux-keyring
sudo pacman -Syu
```

### Ubuntu: "add-apt-repository: command not found"

```bash
sudo apt install software-properties-common
```

### Windows: Long path errors

```powershell
# Enable long paths (admin PowerShell)
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" `
    -Name "LongPathsEnabled" -Value 1 -PropertyType DWORD -Force
```

### WSL: GUI applications don't work

```bash
# Install WSLg support (Windows 11)
wsl --update

# For matplotlib in WSL
pip install matplotlib
# Use non-interactive backend:
export MPLBACKEND=Agg
```

---

## Network Issues

### "Could not find a version that satisfies the requirement"

```bash
# Check internet connectivity
curl -I https://pypi.org

# Try a different PyPI mirror
pip install --index-url https://pypi.org/simple/ qiskit

# Behind a proxy?
pip install --proxy http://proxy:port qiskit
```

### Download timeouts

```bash
# Increase pip timeout
pip install --timeout 120 qiskit

# Or download packages separately
pip download qiskit -d ./packages
pip install --no-index --find-links ./packages qiskit
```

---

## Still Stuck?

1. **Run the verification script** to see what's failing:
   ```bash
   qenv && qtest
   ```

2. **Search existing issues:**
   [GitHub Issues](https://github.com/your-username/quantum-dev-env/issues)

3. **Open a new issue** with:
   - Your OS and version (`cat /etc/os-release`)
   - Python version (`python3 --version`)
   - The full error message
   - Steps to reproduce

4. **Check framework documentation:**
   - [Qiskit Docs](https://docs.quantum.ibm.com/)
   - [Cirq Docs](https://quantumai.google/cirq)
   - [PennyLane Docs](https://docs.pennylane.ai/)
