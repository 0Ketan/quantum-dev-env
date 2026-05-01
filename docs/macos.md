# 🍎 macOS Installation Guide

> **One-command quantum computing setup for macOS — Apple Silicon & Intel.**

## Prerequisites

- **macOS 12 (Monterey) or later** (recommended)
- **Terminal access** (built-in Terminal.app, iTerm2, or any terminal emulator)
- **Internet connection**
- Approximately **3 GB** of free disk space

That's it! The installer handles everything else automatically.

## Quick Install

Open Terminal and run:

```bash
git clone https://github.com/0Ketan/quantum-dev-env.git
cd quantum-dev-env
chmod +x setup.sh
./setup.sh
```

### One-Liner

```bash
git clone https://github.com/0Ketan/quantum-dev-env.git && cd quantum-dev-env && chmod +x setup.sh && ./setup.sh
```

### Skip Confirmation Prompts

```bash
./setup.sh --yes
```

### Custom Install Directory

```bash
./setup.sh --dir ~/my-quantum-project
```

## What Gets Installed

The installer performs the following steps automatically:

| Step | What | Details |
|------|------|---------|
| 1 | **Xcode CLI Tools** | Required for compiling native extensions |
| 2 | **Homebrew** | macOS package manager (if not already installed) |
| 3 | **Python 3.11** | Via `brew install python@3.11` |
| 4 | **Git** | Via Homebrew |
| 5 | **VS Code** | Via `brew install --cask visual-studio-code` |
| 6 | **Virtual Environment** | Created at `~/quantum/.venv` |
| 7 | **Quantum Packages** | Qiskit, Cirq, PennyLane, NumPy, SciPy, Pandas, Matplotlib, Jupyter |
| 8 | **Shell Aliases** | `qenv`, `qcd`, `qtest`, `qjupyter`, `qlab` |
| 9 | **VS Code Settings** | Pre-configured Python + Jupyter workspace |

### Python Packages Installed

| Category | Packages |
|----------|----------|
| **Quantum Frameworks** | `qiskit`, `qiskit-aer`, `qiskit-ibm-runtime`, `cirq`, `pennylane` |
| **Scientific Computing** | `numpy`, `scipy`, `matplotlib`, `pandas` |
| **Development Tools** | `jupyter`, `ipykernel` |

## After Installation

### Activate the Environment

```bash
qenv          # Activate the quantum virtual environment
```

Or manually:

```bash
source ~/quantum/.venv/bin/activate
```

### Run a Quick Test

```bash
qenv
qtest         # Run the verification script
```

### Run an Example

```bash
qenv
python ~/quantum/examples/01-hello-quantum.py
```

### Start Jupyter Notebook

```bash
qenv
jupyter notebook
```

### Open in VS Code

```bash
qcd && code .
```

## Shell Aliases Reference

These aliases are added to your shell configuration (`~/.zshrc`, `~/.bash_profile`, or `~/.config/fish/config.fish`):

| Alias | Action |
|-------|--------|
| `qenv` | Activate the quantum virtual environment |
| `qcd` | Navigate to `~/quantum` |
| `qtest` | Run the installation verification script |
| `qjupyter` | Start Jupyter Notebook in the quantum directory |
| `qlab` | Start Jupyter Lab in the quantum directory |

## Apple Silicon vs Intel

The installer automatically detects your Mac's architecture and adapts:

| Feature | Apple Silicon (M1/M2/M3/M4) | Intel |
|---------|-------------------------------|-------|
| Homebrew path | `/opt/homebrew` | `/usr/local` |
| Python packages | Native ARM binaries | x86_64 binaries |
| Performance | Excellent | Good |
| Rosetta 2 | Not required | N/A |

All quantum packages (Qiskit, Cirq, PennyLane) have native Apple Silicon support as of 2024.

## Troubleshooting

### Xcode Command Line Tools Dialog

**Problem:** A system dialog pops up asking to install Xcode Command Line Tools.

**Solution:** Click **Install** in the dialog and wait for it to finish. The installer will wait automatically. If the dialog doesn't appear, run manually:

```bash
xcode-select --install
```

### "command not found: brew" After Installation

**Problem:** Homebrew isn't found in your PATH after the installer adds it.

**Solution:** Restart your terminal, or run:

```bash
# Apple Silicon
eval "$(/opt/homebrew/bin/brew shellenv)"

# Intel
eval "$(/usr/local/bin/brew shellenv)"
```

### "command not found: qenv" After Installation

**Problem:** The shell aliases aren't available.

**Solution:** Restart your terminal or source your shell config:

```bash
# zsh (default on macOS)
source ~/.zshrc

# bash
source ~/.bash_profile

# fish
source ~/.config/fish/config.fish
```

### Python Package Build Failures on Apple Silicon

**Problem:** A pip package fails to build with compilation errors on M1/M2/M3.

**Solution:**

1. **Update pip and setuptools:**
   ```bash
   qenv
   pip install --upgrade pip setuptools wheel
   ```

2. **Install with no-binary fallback:**
   ```bash
   pip install --no-cache-dir <package-name>
   ```

3. **If a specific package needs Rosetta:**
   ```bash
   arch -x86_64 pip install <package-name>
   ```

### "No module named _tkinter"

**Problem:** Matplotlib or other GUI-dependent packages can't find tkinter.

**Solution:**

```bash
brew install python-tk@3.11
```

### Homebrew Python vs System Python

**Problem:** The wrong Python version is being used.

**Solution:** The installer configures the virtual environment with Homebrew's Python 3.11. Always use the `qenv` alias to activate the correct environment:

```bash
qenv
which python    # Should show ~/quantum/.venv/bin/python
python --version  # Should show Python 3.11.x
```

If you need to force Homebrew Python:

```bash
# Apple Silicon
/opt/homebrew/bin/python3.11 --version

# Intel
/usr/local/bin/python3.11 --version
```

### Permission Denied Errors

**Problem:** The script fails with permission errors.

**Solution:**

```bash
chmod +x setup.sh
chmod +x scripts/install-macos.sh
./setup.sh
```

Do **not** run the installer with `sudo` — Homebrew should not be run as root.

### Slow Installation on Apple Silicon

**Problem:** Package installation is very slow.

**Solution:** Some packages may need to compile from source on ARM. This is normal for the first install. Subsequent installs will use cached wheels. Expect 5–15 minutes for a full fresh install.

## Uninstalling

To completely remove the quantum development environment:

```bash
# Remove the project directory
rm -rf ~/quantum

# Remove shell aliases (edit your shell config)
# For zsh:
nano ~/.zshrc
# Delete the block between "# >>> quantum-dev-env aliases >>>" and "# <<< quantum-dev-env aliases <<<"

# Optionally remove the Jupyter kernel
jupyter kernelspec uninstall quantum-env
```

This does **not** remove Homebrew, Python, or VS Code — those are shared system tools.

## Advanced Configuration

### Using a Different Python Version

```bash
brew install python@3.12
./setup.sh --dir ~/quantum-312
# Then manually point the venv to Python 3.12
```

### Using with Conda

If you prefer Conda over venv:

```bash
brew install --cask miniconda
conda create -n quantum python=3.11
conda activate quantum
pip install qiskit qiskit-aer cirq pennylane jupyter
```

### Connecting to IBM Quantum

```python
from qiskit_ibm_runtime import QiskitRuntimeService

# Save your API token (one-time setup)
QiskitRuntimeService.save_account(
    channel="ibm_quantum",
    token="YOUR_IBM_QUANTUM_API_TOKEN"
)

# Load and use
service = QiskitRuntimeService()
backends = service.backends()
print(backends)
```

Get your free API token at [IBM Quantum](https://quantum.ibm.com/).
