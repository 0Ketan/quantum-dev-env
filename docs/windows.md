# 🪟 Windows Installation Guide

Manual installation guide for Windows 10 and Windows 11.

> [!TIP]
> For automatic installation, use `scripts/install-windows.ps1` in PowerShell. This guide is for manual setup or troubleshooting.

---

## Prerequisites

- Windows 10 (version 1903+) or Windows 11
- PowerShell 5.1+ (pre-installed on Windows 10/11)
- Internet connection
- Administrator access (for some installations)

## Step 1: Install Python

### Option A: Via winget (recommended)

Open PowerShell and run:

```powershell
winget install Python.Python.3.11
```

### Option B: From python.org

1. Go to [python.org/downloads](https://www.python.org/downloads/)
2. Download Python 3.11+ installer
3. **Important:** Check ✅ "Add Python to PATH" during installation
4. Click "Install Now"

### Verify Python

```powershell
python --version
# Should show: Python 3.11.x (or higher)

pip --version
# Should show pip version and Python path
```

> [!IMPORTANT]
> If `python` is not recognized after installation, restart your terminal or add Python to your PATH manually.

## Step 2: Install Git

### Via winget

```powershell
winget install Git.Git
```

### Or from git-scm.com

Download from [git-scm.com](https://git-scm.com/download/windows) and install with default settings.

## Step 3: Install VS Code

### Via winget

```powershell
winget install Microsoft.VisualStudioCode
```

### Or from code.visualstudio.com

Download from [code.visualstudio.com](https://code.visualstudio.com/) and install.

## Step 4: Create Project Directory

```powershell
mkdir $env:USERPROFILE\quantum
cd $env:USERPROFILE\quantum
```

## Step 5: Set Up Virtual Environment

```powershell
python -m venv .venv
.venv\Scripts\Activate.ps1
```

> [!NOTE]
> If you get an execution policy error, run:
> ```powershell
> Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
> ```

## Step 6: Install Quantum Packages

```powershell
pip install --upgrade pip

pip install `
    qiskit `
    qiskit-aer `
    qiskit-ibm-runtime `
    cirq `
    pennylane `
    numpy `
    matplotlib `
    scipy `
    jupyter `
    ipykernel
```

## Step 7: Register Jupyter Kernel

```powershell
python -m ipykernel install --user `
    --name quantum-env `
    --display-name "Quantum Computing (Python)"
```

## Step 8: Configure VS Code

1. Open VS Code in your quantum directory:
   ```powershell
   code $env:USERPROFILE\quantum
   ```

2. Create `.vscode\settings.json` using the template from [configs/vscode-settings.json](../configs/vscode-settings.json)

3. Install extensions:
   ```powershell
   code --install-extension ms-python.python
   code --install-extension ms-toolsai.jupyter
   code --install-extension ms-python.black-formatter
   ```

## Step 9: Add PowerShell Functions

Add convenience functions to your PowerShell profile:

```powershell
# Open your profile for editing
notepad $PROFILE
```

Add these lines:

```powershell
# >>> quantum-dev-env >>>
function qenv { & "$env:USERPROFILE\quantum\.venv\Scripts\Activate.ps1" }
function qcd { Set-Location "$env:USERPROFILE\quantum" }
function qtest { & "$env:USERPROFILE\quantum\.venv\Scripts\python.exe" "$env:USERPROFILE\quantum\verify-setup.py" }
# <<< quantum-dev-env <<<
```

Save and reload:

```powershell
. $PROFILE
```

## Step 10: Verify Installation

```powershell
qenv
python verify-setup.py
```

---

## WSL Alternative

If you prefer a Linux environment on Windows, you can use Windows Subsystem for Linux:

### Install WSL

```powershell
wsl --install -d Ubuntu
```

### Set Up Quantum Environment in WSL

```bash
# Inside WSL Ubuntu terminal
git clone https://github.com/0Ketan/quantum-dev-env.git
cd quantum-dev-env
chmod +x setup.sh
./setup.sh
```

> [!TIP]
> WSL gives you the best of both worlds: Linux tools with Windows desktop. VS Code has excellent WSL integration via the "Remote - WSL" extension.

---

## Troubleshooting

### "python" is not recognized

1. Restart your terminal
2. Check if Python is in PATH:
   ```powershell
   $env:PATH -split ";"  | Where-Object { $_ -like "*Python*" }
   ```
3. Manually add Python to PATH:
   ```powershell
   # Find Python location
   Get-Command python -ErrorAction SilentlyContinue | Select-Object Source
   ```

### Execution policy error

```powershell
# Set for current user only (recommended)
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

# Or for current session only
Set-ExecutionPolicy Bypass -Scope Process
```

### "pip" is not recognized

```powershell
# Use Python module syntax instead
python -m pip install <package>
```

### Build errors during package install

Some packages need C++ build tools:

```powershell
# Install Visual Studio Build Tools
winget install Microsoft.VisualStudio.2022.BuildTools

# Or download from:
# https://visualstudio.microsoft.com/visual-cpp-build-tools/
```

During installation, select "Desktop development with C++".

### VS Code doesn't find the Python interpreter

1. Open VS Code Command Palette (`Ctrl+Shift+P`)
2. Type "Python: Select Interpreter"
3. Choose the interpreter at `~/quantum/.venv/Scripts/python.exe`

### Long path issues

If you encounter path length errors:

```powershell
# Enable long paths (requires admin)
New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" `
    -Name "LongPathsEnabled" -Value 1 -PropertyType DWORD -Force
```

See [troubleshooting.md](troubleshooting.md) for more common issues.
