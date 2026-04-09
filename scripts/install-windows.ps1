<#
.SYNOPSIS
    Quantum Dev Environment Installer for Windows 10/11

.DESCRIPTION
    This script installs a complete quantum computing development environment
    on Windows, including Python, VS Code, and all quantum computing packages
    (Qiskit, Cirq, PennyLane).

.PARAMETER Confirm
    Skip confirmation prompts (auto-accept all)

.PARAMETER QuantumDir
    Set the quantum project directory (default: $HOME\quantum)

.EXAMPLE
    .\install-windows.ps1
    .\install-windows.ps1 -Confirm
    .\install-windows.ps1 -QuantumDir "D:\quantum"

.NOTES
    Requires: Windows 10/11, PowerShell 5.1+, Administrator privileges (for winget)
#>

param(
    [switch]$AutoConfirm,
    [string]$QuantumDir = "$env:USERPROFILE\quantum",
    [switch]$Help
)

# ==============================================================================
# Configuration
# ==============================================================================

$ErrorActionPreference = "Stop"

$QuantumPackages = @(
    "qiskit",
    "qiskit-aer",
    "qiskit-ibm-runtime",
    "cirq",
    "pennylane",
    "numpy",
    "matplotlib",
    "scipy",
    "jupyter",
    "ipykernel"
)

$VenvDir = Join-Path $QuantumDir ".venv"

# ==============================================================================
# Output Functions
# ==============================================================================

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Error2 {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Cyan
}

function Write-Warn {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Write-Step {
    param([string]$StepNum, [string]$Message)
    Write-Host ""
    Write-Host "[$StepNum] $Message" -ForegroundColor Magenta
    Write-Host ("─" * 60) -ForegroundColor Magenta
}

function Write-Banner {
    param([string]$Message)
    $border = "═" * ($Message.Length + 4)
    Write-Host ""
    Write-Host "╔$border╗" -ForegroundColor Cyan
    Write-Host "║  $Message  ║" -ForegroundColor Cyan
    Write-Host "╚$border╝" -ForegroundColor Cyan
    Write-Host ""
}

# ==============================================================================
# Help
# ==============================================================================

function Show-Help {
    @"
Usage: .\install-windows.ps1 [OPTIONS]

Install quantum computing development environment on Windows 10/11.

Options:
  -AutoConfirm    Skip confirmation prompts
  -QuantumDir     Set quantum project directory (default: ~\quantum)
  -Help           Show this help message

What gets installed:
  System: Python 3.11+, VS Code, Git
  Python: qiskit, cirq, pennylane, jupyter, numpy, matplotlib, scipy

Examples:
  .\install-windows.ps1
  .\install-windows.ps1 -AutoConfirm
  .\install-windows.ps1 -QuantumDir "D:\my-quantum"
"@
}

# ==============================================================================
# Utility Functions
# ==============================================================================

function Test-CommandExists {
    param([string]$Command)
    $null = Get-Command $Command -ErrorAction SilentlyContinue
    return $?
}

function Test-InternetConnection {
    Write-Info "Checking internet connectivity..."
    try {
        $response = Invoke-WebRequest -Uri "https://pypi.org" -UseBasicParsing `
                    -TimeoutSec 5 -ErrorAction Stop
        Write-Success "Internet connection verified"
        return $true
    }
    catch {
        Write-Error2 "No internet connection detected"
        Write-Info "Please check your network and try again"
        return $false
    }
}

function Get-PythonCommand {
    # Try common Python command names on Windows
    foreach ($cmd in @("python", "python3", "py")) {
        if (Test-CommandExists $cmd) {
            $version = & $cmd --version 2>&1
            if ($version -match "Python 3\.") {
                return $cmd
            }
        }
    }
    return $null
}

# ==============================================================================
# Installation Functions
# ==============================================================================

function Confirm-Installation {
    if ($AutoConfirm) { return }

    Write-Host "The following will be installed:" -ForegroundColor White
    Write-Host ""
    Write-Host "  📦 Python 3.11+ (if not installed)"
    Write-Host "  🖥️  VS Code (if not installed)"
    Write-Host "  🐍 Packages: $($QuantumPackages -join ', ')"
    Write-Host "  📂 Directory: $QuantumDir"
    Write-Host ""

    $choice = Read-Host "Proceed with installation? (Y/n)"
    if ($choice -match "^[Nn]") {
        Write-Info "Installation cancelled"
        exit 0
    }
}

function Install-Python {
    Write-Step "1/6" "Checking Python installation"

    $pythonCmd = Get-PythonCommand

    if ($pythonCmd) {
        $version = & $pythonCmd --version 2>&1
        Write-Success "Python found: $version"

        # Check version >= 3.8
        $versionNum = ($version -replace "Python ", "")
        $parts = $versionNum.Split(".")
        if ([int]$parts[0] -ge 3 -and [int]$parts[1] -ge 8) {
            Write-Success "Python version is compatible (>= 3.8)"
            return $pythonCmd
        }
        else {
            Write-Warn "Python version $versionNum is too old (need >= 3.8)"
        }
    }

    Write-Info "Installing Python via winget..."
    try {
        winget install Python.Python.3.11 --accept-source-agreements `
              --accept-package-agreements --silent 2>&1 | Out-Null
        Write-Success "Python 3.11 installed"

        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" `
                   + [System.Environment]::GetEnvironmentVariable("Path", "User")

        $pythonCmd = Get-PythonCommand
        if (-not $pythonCmd) {
            Write-Error2 "Python installed but not found in PATH"
            Write-Info "Please restart your terminal and run this script again"
            exit 1
        }
        return $pythonCmd
    }
    catch {
        Write-Error2 "Failed to install Python via winget"
        Write-Info "Please install Python manually from https://www.python.org/downloads/"
        Write-Info "Make sure to check 'Add Python to PATH' during installation"
        exit 1
    }
}

function Install-VSCode {
    Write-Step "2/6" "Checking VS Code installation"

    if (Test-CommandExists "code") {
        Write-Success "VS Code is already installed"
        return
    }

    Write-Info "Installing VS Code via winget..."
    try {
        winget install Microsoft.VisualStudioCode --accept-source-agreements `
              --accept-package-agreements --silent 2>&1 | Out-Null
        Write-Success "VS Code installed"
    }
    catch {
        Write-Warn "Could not install VS Code automatically"
        Write-Info "Install manually: https://code.visualstudio.com/"
    }
}

function Setup-Project {
    param([string]$PythonCmd)

    Write-Step "3/6" "Setting up project directory"

    if (-not (Test-Path $QuantumDir)) {
        New-Item -ItemType Directory -Path $QuantumDir -Force | Out-Null
        Write-Success "Created directory: $QuantumDir"
    }
    else {
        Write-Info "Directory already exists: $QuantumDir"
    }

    # Create virtual environment
    if (Test-Path $VenvDir) {
        Write-Warn "Virtual environment already exists at: $VenvDir"
        if (-not $AutoConfirm) {
            $recreate = Read-Host "Recreate it? (y/N)"
            if ($recreate -match "^[Yy]") {
                Remove-Item -Path $VenvDir -Recurse -Force
            }
            else {
                Write-Info "Keeping existing virtual environment"
                return
            }
        }
    }

    Write-Info "Creating virtual environment..."
    & $PythonCmd -m venv $VenvDir
    Write-Success "Virtual environment created at: $VenvDir"
}

function Install-QuantumPackages {
    Write-Step "4/6" "Installing quantum computing packages"

    $pipCmd = Join-Path $VenvDir "Scripts\pip.exe"

    Write-Info "Upgrading pip..."
    & $pipCmd install --upgrade pip --quiet 2>$null

    Write-Info "Installing $($QuantumPackages.Count) packages (this may take a few minutes)..."
    Write-Host ""

    $failed = @()
    foreach ($pkg in $QuantumPackages) {
        $padded = $pkg.PadRight(30)
        Write-Host "  $padded" -NoNewline
        try {
            & $pipCmd install $pkg --quiet 2>$null
            Write-Host "✅ installed" -ForegroundColor Green
        }
        catch {
            Write-Host "❌ failed" -ForegroundColor Red
            $failed += $pkg
        }
    }

    Write-Host ""

    if ($failed.Count -gt 0) {
        Write-Warn "Some packages failed: $($failed -join ', ')"
    }
    else {
        Write-Success "All packages installed successfully"
    }

    # Register Jupyter kernel
    Write-Info "Registering Jupyter kernel..."
    $pythonCmd = Join-Path $VenvDir "Scripts\python.exe"
    try {
        & $pythonCmd -m ipykernel install --user --name quantum-env `
                     --display-name "Quantum Computing (Python)" 2>$null
        Write-Success "Jupyter kernel registered"
    }
    catch {
        Write-Warn "Failed to register Jupyter kernel (non-critical)"
    }
}

function Configure-Environment {
    Write-Step "5/6" "Configuring development environment"

    $scriptRoot = Split-Path -Parent $PSScriptRoot
    if (-not $scriptRoot) {
        $scriptRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
    }

    # Copy VS Code settings
    $vscodeDir = Join-Path $QuantumDir ".vscode"
    if (-not (Test-Path $vscodeDir)) {
        New-Item -ItemType Directory -Path $vscodeDir -Force | Out-Null
    }

    $settingsSrc = Join-Path $scriptRoot "configs\vscode-settings.json"
    if (Test-Path $settingsSrc) {
        Copy-Item $settingsSrc (Join-Path $vscodeDir "settings.json") -Force
        Write-Success "VS Code settings configured"
    }

    # Copy examples
    $examplesSrc = Join-Path $scriptRoot "examples"
    $examplesDst = Join-Path $QuantumDir "examples"
    if (Test-Path $examplesSrc) {
        if (-not (Test-Path $examplesDst)) {
            New-Item -ItemType Directory -Path $examplesDst -Force | Out-Null
        }
        Copy-Item "$examplesSrc\*" $examplesDst -Force -Recurse
        Write-Success "Example programs copied"
    }

    # Copy verify script
    $verifySrc = Join-Path $scriptRoot "scripts\verify-setup.py"
    if (Test-Path $verifySrc) {
        Copy-Item $verifySrc (Join-Path $QuantumDir "verify-setup.py") -Force
        Write-Success "Verification script copied"
    }

    # Create PowerShell profile function
    Write-Info "Setting up PowerShell profile..."
    $profileDir = Split-Path $PROFILE -Parent
    if (-not (Test-Path $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }

    if (-not (Test-Path $PROFILE)) {
        New-Item -ItemType File -Path $PROFILE -Force | Out-Null
    }

    $marker = "# >>> quantum-dev-env >>>"
    $profileContent = Get-Content $PROFILE -Raw -ErrorAction SilentlyContinue
    if (-not ($profileContent -and $profileContent.Contains($marker))) {
        $profileAddition = @"

$marker
function qenv { & "$VenvDir\Scripts\Activate.ps1" }
function qcd { Set-Location "$QuantumDir" }
function qtest { & "$VenvDir\Scripts\python.exe" "$QuantumDir\verify-setup.py" }
# <<< quantum-dev-env <<<
"@
        Add-Content -Path $PROFILE -Value $profileAddition
        Write-Success "PowerShell profile functions added (qenv, qcd, qtest)"
    }
    else {
        Write-Info "PowerShell profile already configured"
    }
}

function Run-Verification {
    Write-Step "6/6" "Verifying installation"

    $pythonCmd = Join-Path $VenvDir "Scripts\python.exe"
    $verifyScript = Join-Path $QuantumDir "verify-setup.py"

    if (Test-Path $verifyScript) {
        try {
            & $pythonCmd $verifyScript
        }
        catch {
            Write-Warn "Some verification checks failed"
        }
    }
    else {
        Write-Warn "Verification script not found"
    }
}

function Show-SuccessMessage {
    Write-Banner "🎉 Quantum Dev Environment Ready!"

    Write-Host "Your quantum computing environment is set up!" -ForegroundColor Green
    Write-Host ""
    Write-Host "📂 Project directory: $QuantumDir" -ForegroundColor Cyan
    Write-Host "🐍 Virtual environment: $VenvDir" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Quick Start:" -ForegroundColor White
    Write-Host "  qenv          → Activate the quantum environment" -ForegroundColor Yellow
    Write-Host "  qcd           → Navigate to the quantum directory" -ForegroundColor Yellow
    Write-Host "  qtest         → Verify your installation" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Run an example:" -ForegroundColor White
    Write-Host "  qenv" -ForegroundColor Yellow
    Write-Host "  python examples\01-hello-quantum.py" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Start Jupyter:" -ForegroundColor White
    Write-Host "  qenv" -ForegroundColor Yellow
    Write-Host "  jupyter notebook" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Happy quantum computing! 🚀" -ForegroundColor Magenta
}

# ==============================================================================
# Main
# ==============================================================================

if ($Help) {
    Show-Help
    exit 0
}

Write-Banner "🚀 Quantum Dev Environment - Windows Installer"

# Check execution policy
$policy = Get-ExecutionPolicy
if ($policy -eq "Restricted") {
    Write-Warn "PowerShell execution policy is 'Restricted'"
    Write-Info "Setting execution policy to RemoteSigned for current user..."
    try {
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
        Write-Success "Execution policy updated"
    }
    catch {
        Write-Error2 "Failed to set execution policy"
        Write-Info "Run: Set-ExecutionPolicy RemoteSigned -Scope CurrentUser"
        exit 1
    }
}

Confirm-Installation

if (-not (Test-InternetConnection)) {
    exit 1
}

$startTime = Get-Date
$pythonCmd = Install-Python
Install-VSCode
Setup-Project -PythonCmd $pythonCmd
Install-QuantumPackages
Configure-Environment
Run-Verification

$elapsed = (Get-Date) - $startTime
Write-Info ("Installation completed in {0:N0}m {1:N0}s" -f $elapsed.TotalMinutes, ($elapsed.Seconds))

Show-SuccessMessage
