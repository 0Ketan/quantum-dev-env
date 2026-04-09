<div align="center">

# ⚛️ Quantum Dev Environment

**One-command quantum computing development environment setup.**

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Platform: Linux](https://img.shields.io/badge/Platform-Linux-orange.svg)](#-supported-platforms)
[![Platform: Windows](https://img.shields.io/badge/Platform-Windows-0078D6.svg)](#-supported-platforms)
[![Python 3.8+](https://img.shields.io/badge/Python-3.8+-3776AB.svg)](https://www.python.org/)
[![Qiskit](https://img.shields.io/badge/Qiskit-✓-6929C4.svg)](https://qiskit.org/)
[![Cirq](https://img.shields.io/badge/Cirq-✓-FBBC04.svg)](https://quantumai.google/cirq)
[![PennyLane](https://img.shields.io/badge/PennyLane-✓-00C853.svg)](https://pennylane.ai/)

*Set up Qiskit, Cirq, PennyLane, Jupyter, and VS Code in under 5 minutes.*

---

</div>

## 🤔 Why This Exists

Getting started with quantum computing shouldn't require hours of dependency hunting. This project gives you a **complete, ready-to-use quantum development environment** with a single command — on any major platform.

Whether you're a **student** taking your first quantum computing class, a **researcher** prototyping new algorithms, or a **hobbyist** exploring the quantum world, this gets you from zero to running quantum circuits in minutes.

## ⚡ Quick Start

### Linux (Arch, Manjaro, Ubuntu, Debian, Mint)

```bash
git clone https://github.com/0Ketan/quantum-dev-env.git
cd quantum-dev-env
chmod +x setup.sh
./setup.sh
```

### Windows 10/11 (PowerShell)

```powershell
git clone https://github.com/0Ketan/quantum-dev-env.git
cd quantum-dev-env
powershell -ExecutionPolicy Bypass -File scripts/install-windows.ps1
```

### One-Liner (Linux)

```bash
git clone https://github.com/0Ketan/quantum-dev-env.git && cd quantum-dev-env && chmod +x setup.sh && ./setup.sh
```

That's it! ☕ Grab a coffee while it installs.

## 📦 What Gets Installed

| Category | Packages |
|----------|----------|
| **Quantum Frameworks** | Qiskit, Qiskit Aer, Qiskit IBM Runtime, Cirq, PennyLane |
| **Scientific Python** | NumPy, SciPy, Matplotlib |
| **Development Tools** | Jupyter Notebook, IPyKernel, VS Code |
| **System** | Python 3.11+, pip, git, build tools |

Everything is installed in an **isolated virtual environment** (`~/quantum/.venv`) — your system Python stays untouched.

## 🖥️ Supported Platforms

| Platform | Status | Installer |
|----------|--------|-----------|
| 🐧 Arch Linux | ✅ Fully Supported | `install-arch.sh` |
| 🐧 Manjaro | ✅ Fully Supported | `install-arch.sh` |
| 🐧 CachyOS | ✅ Fully Supported | `install-arch.sh` |
| 🐧 Garuda Linux | ✅ Fully Supported | `install-arch.sh` |
| 🐧 Ubuntu | ✅ Fully Supported | `install-debian.sh` |
| 🐧 Debian | ✅ Fully Supported | `install-debian.sh` |
| 🐧 Linux Mint | ✅ Fully Supported | `install-debian.sh` |
| 🐧 Pop!_OS | ✅ Fully Supported | `install-debian.sh` |
| 🪟 Windows 10 | ✅ Fully Supported | `install-windows.ps1` |
| 🪟 Windows 11 | ✅ Fully Supported | `install-windows.ps1` |
| 🐧 WSL | ✅ Fully Supported | Auto-detected |
| 🍎 macOS | 🔜 Planned | — |

## 📖 Manual Installation

If you prefer to install manually or need to troubleshoot:

- **[Arch-based Linux Guide](docs/arch-based.md)** — Arch, Manjaro, CachyOS, Garuda
- **[Debian-based Linux Guide](docs/debian-based.md)** — Ubuntu, Debian, Mint
- **[Windows Guide](docs/windows.md)** — Windows 10/11, WSL

## ✅ Verify Installation

After installation, verify everything works:

```bash
qenv          # Activate the environment
qtest         # Run verification checks
```

Or manually:

```bash
source ~/quantum/.venv/bin/activate
python ~/quantum/verify-setup.py
```

You should see ✅ for each package and a successful Bell state simulation.

## 🧪 Example Programs

The installer includes four beginner-friendly quantum programs:

| # | Example | Description |
|---|---------|-------------|
| 01 | [Hello Quantum](examples/01-hello-quantum.py) | Your first qubit in superposition |
| 02 | [Bell State](examples/02-bell-state.py) | Quantum entanglement demo |
| 03 | [Superposition](examples/03-superposition.py) | Statistical analysis of superposition |
| 04 | [Teleportation](examples/04-quantum-teleportation.py) | Full teleportation protocol |

Run an example:

```bash
qenv                                             # Activate environment
python ~/quantum/examples/01-hello-quantum.py    # Run example
```

Start Jupyter for interactive exploration:

```bash
qenv
jupyter notebook
```

## 🔧 Quick Commands

After installation, these aliases are available:

| Command | Action |
|---------|--------|
| `qenv` | Activate the quantum virtual environment |
| `qcd` | Navigate to `~/quantum` |
| `qtest` | Run the verification script |
| `qjupyter` | Start Jupyter Notebook |
| `qlab` | Start Jupyter Lab |

## 🐛 Troubleshooting

Having issues? Check:

1. **[Troubleshooting Guide](docs/troubleshooting.md)** — Common problems and solutions
2. **[GitHub Issues](https://github.com/0Ketan/quantum-dev-env/issues)** — Search existing issues
3. **Open a new issue** — Use our [bug report template](.github/ISSUE_TEMPLATE/bug_report.md)

Common quick fixes:

```bash
# "command not found" after install → restart your terminal
source ~/.bashrc  # or ~/.zshrc

# Package import errors → make sure venv is active
qenv
pip install --upgrade qiskit cirq pennylane

# Python version issues
python3 --version  # Should be 3.8+
```

## ❓ FAQ

<details>
<summary><b>Do I need a quantum computer?</b></summary>

No! All examples run on a simulator (Qiskit Aer) that runs on your regular computer. You can optionally connect to real IBM quantum hardware for free via IBM Quantum.
</details>

<details>
<summary><b>Will this modify my system Python?</b></summary>

No. Everything is installed in an isolated virtual environment at `~/quantum/.venv`. Your system Python is never modified.
</details>

<details>
<summary><b>How much disk space does this need?</b></summary>

Approximately 2-3 GB for all packages and dependencies.
</details>

<details>
<summary><b>Can I use this with Conda?</b></summary>

The default setup uses Python venv. If you prefer Conda, see the manual installation guides in `docs/`.
</details>

<details>
<summary><b>How do I uninstall?</b></summary>

Simply delete the quantum directory and remove the aliases from your shell config:

```bash
rm -rf ~/quantum
# Remove the "quantum-dev-env aliases" block from ~/.bashrc or ~/.zshrc
```
</details>

<details>
<summary><b>Can I use a different project directory?</b></summary>

Yes! Use the `--dir` flag:

```bash
./setup.sh --dir ~/my-quantum-project
```
</details>

## 🤝 Contributing

Contributions are welcome! Please see our [Contributing Guide](docs/contributing.md) for details on:

- Reporting bugs
- Suggesting features
- Submitting pull requests
- Code style guidelines

## 📄 License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- [Qiskit](https://qiskit.org/) by IBM — Open-source quantum computing framework
- [Cirq](https://quantumai.google/cirq) by Google — Framework for NISQ algorithms
- [PennyLane](https://pennylane.ai/) by Xanadu — Differentiable quantum computing
- [Jupyter](https://jupyter.org/) — Interactive computing notebooks
- The open-source quantum computing community ❤️

---

<div align="center">

**If this helped you get started with quantum computing, consider giving it a ⭐!**

*Built with ❤️ for the quantum computing community*

</div>