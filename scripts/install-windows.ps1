<#
.SYNOPSIS
    Quantum Dev Environment Installer for Windows 10/11

.DESCRIPTION
    This script installs a complete quantum computing development environment
    on Windows, including Python, VS Code, Git, and all quantum computing packages
    (Qiskit, Cirq, PennyLane).

.PARAMETER AutoConfirm
    Skip confirmation prompts (auto-accept all)

.PARAMETER QuantumDir
    Set the quantum project directory (default: $HOME\quantum)

.PARAMETER Help
    Show help message

.EXAMPLE
    .\install-windows.ps1
    .\install-windows.ps1 -AutoConfirm
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

# Use "Continue" globally to prevent stderr from native commands (winget, pip)
# from terminating the script. We handle errors explicitly with $LASTEXITCODE.
$ErrorActionPreference = "Continue"

$QuantumPackages = @(
    "qiskit",
    "qiskit-aer",
    "qiskit-ibm-runtime",
    "cirq",
    "pennylane",
    "numpy",
    "matplotlib",
    "scipy",
    "pandas",
    "jupyter",
    "ipykernel"
)

$VenvDir = Join-Path $QuantumDir ".venv"

# ==============================================================================
# Resolve script root directory (repo root)
# ==============================================================================

# $PSScriptRoot points to scripts/ - go one level up for the repo root.
# We add fallbacks for cases where $PSScriptRoot is empty (e.g., pasting
# into a console or running via Invoke-Expression).
$ScriptRoot = $null

if ($PSScriptRoot) {
    $ScriptRoot = Split-Path -Parent $PSScriptRoot
}

if (-not $ScriptRoot -and $MyInvocation.MyCommand.Path) {
    # MyInvocation.MyCommand.Path = full path to .ps1 file
    # Split twice: once to get scripts/, again to get repo root
    $ScriptRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
}

if (-not $ScriptRoot) {
    # Last resort: assume current directory is the repo root
    # Cast to string so Join-Path works correctly (Get-Location returns PathInfo)
    $ScriptRoot = (Get-Location).Path
}

# ==============================================================================
# Output Functions
# ==============================================================================

function Write-Success {
    param([string]$Message)
    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Error2 {
    param([string]$Message)
    Write-Host "[ERR] $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-Warn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-Step {
    param([string]$StepNum, [string]$Message)
    Write-Host ""
    Write-Host "[$StepNum] $Message" -ForegroundColor Magenta
    Write-Host ("-" * 60) -ForegroundColor Magenta
}

function Write-Banner {
    param([string]$Message)
    $border = "=" * ($Message.Length + 4)
    Write-Host ""
    Write-Host "+$border+" -ForegroundColor Cyan
    Write-Host "|  $Message  |" -ForegroundColor Cyan
    Write-Host "+$border+" -ForegroundColor Cyan
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
  Python: qiskit, cirq, pennylane, jupyter, numpy, matplotlib, scipy, pandas

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

function Test-WingetAvailable {
    if (Test-CommandExists "winget") {
        return $true
    }
    Write-Warn "winget is not available on this system"
    Write-Info "winget comes pre-installed on Windows 11 and recent Windows 10 updates"
    Write-Info "Install it from: https://aka.ms/getwinget"
    return $false
}

function Test-InternetConnection {
    Write-Info "Checking internet connectivity..."
    try {
        $null = Invoke-WebRequest -Uri "https://pypi.org" -UseBasicParsing `
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
            try {
                $version = & $cmd --version 2>&1
                if ($version -match "Python 3\.") {
                    return $cmd
                }
            }
            catch {
                # Skip this command if it fails
            }
        }
    }
    return $null
}

# ==============================================================================
# Installation Functions
# ==============================================================================

function Get-InstallConfirmation {
    if ($AutoConfirm) { return }

    Write-Host "The following will be installed:" -ForegroundColor White
    Write-Host ""
    Write-Host "  - Python 3.11+ (if not installed)"
    Write-Host "  - VS Code (if not installed)"
    Write-Host "  - Git (if not installed)"
    Write-Host "  - Packages: $($QuantumPackages -join ', ')"
    Write-Host "  - Directory: $QuantumDir"
    Write-Host ""

    $choice = Read-Host "Proceed with installation? (Y/n)"
    if ($choice -match "^[Nn]") {
        Write-Info "Installation cancelled"
        exit 0
    }
}

function Install-Python {
    Write-Step "1/7" "Checking Python installation"

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

    if (-not (Test-WingetAvailable)) {
        Write-Error2 "Cannot install Python automatically without winget"
        Write-Info "Please install Python manually from https://www.python.org/downloads/"
        Write-Info "Make sure to check 'Add Python to PATH' during installation"
        exit 1
    }

    Write-Info "Installing Python via winget..."
    # Redirect stdout to $null; keep stderr visible so errors aren't hidden.
    # Do NOT use 2>&1 | Out-Null - that swallows stderr AND breaks $LASTEXITCODE
    # in PowerShell 5.1. Instead redirect only stdout with *>&1 selectively.
    & winget install Python.Python.3.11 --accept-source-agreements `
          --accept-package-agreements --silent | Out-Null

    if ($LASTEXITCODE -ne 0) {
        Write-Error2 "Failed to install Python via winget (exit code: $LASTEXITCODE)"
        Write-Info "Please install Python manually from https://www.python.org/downloads/"
        Write-Info "Make sure to check 'Add Python to PATH' during installation"
        exit 1
    }

    Write-Success "Python 3.11 installed"

    # Refresh PATH so the newly installed Python is found
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

function Install-Git {
    Write-Step "2/7" "Checking Git installation"

    if (Test-CommandExists "git") {
        $gitVersion = & git --version 2>&1
        Write-Success "Git is already installed: $gitVersion"
        return
    }

    if (-not (Test-WingetAvailable)) {
        Write-Warn "Cannot install Git automatically without winget"
        Write-Info "Install manually from: https://git-scm.com/download/windows"
        return
    }

    Write-Info "Installing Git via winget..."
    & winget install Git.Git --accept-source-agreements `
          --accept-package-agreements --silent | Out-Null

    if ($LASTEXITCODE -ne 0) {
        Write-Warn "Could not install Git automatically (exit code: $LASTEXITCODE)"
        Write-Info "Install manually from: https://git-scm.com/download/windows"
    }
    else {
        Write-Success "Git installed"
        # Refresh PATH
        $env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" `
                   + [System.Environment]::GetEnvironmentVariable("Path", "User")
    }
}

function Install-VSCode {
    Write-Step "3/7" "Checking VS Code installation"

    if (Test-CommandExists "code") {
        Write-Success "VS Code is already installed"
        return
    }

    if (-not (Test-WingetAvailable)) {
        Write-Warn "Cannot install VS Code automatically without winget"
        Write-Info "Install manually: https://code.visualstudio.com/"
        return
    }

    Write-Info "Installing VS Code via winget..."
    & winget install Microsoft.VisualStudioCode --accept-source-agreements `
          --accept-package-agreements --silent | Out-Null

    if ($LASTEXITCODE -ne 0) {
        Write-Warn "Could not install VS Code automatically (exit code: $LASTEXITCODE)"
        Write-Info "Install manually: https://code.visualstudio.com/"
    }
    else {
        Write-Success "VS Code installed"
    }
}

function Initialize-Project {
    param([string]$PythonCmd)

    Write-Step "4/7" "Setting up project directory"

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
        else {
            # -AutoConfirm: silently recreate to ensure a clean environment
            Write-Info "Recreating virtual environment (AutoConfirm)..."
            Remove-Item -Path $VenvDir -Recurse -Force
        }
    }

    Write-Info "Creating virtual environment..."
    # Capture output so progress lines don't clutter the console
    $venvOut = & $PythonCmd -m venv $VenvDir 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Error2 "Failed to create virtual environment"
        if ($venvOut) { Write-Host $venvOut -ForegroundColor Red }
        exit 1
    }
    Write-Success "Virtual environment created at: $VenvDir"
}

function Install-QuantumPackages {
    Write-Step "5/7" "Installing quantum computing packages"

    $pipCmd = Join-Path $VenvDir "Scripts\pip.exe"

    if (-not (Test-Path $pipCmd)) {
        Write-Error2 "pip not found at: $pipCmd"
        Write-Info "The virtual environment may not have been created correctly"
        exit 1
    }

    Write-Info "Upgrading pip..."
    # Pipe stdout only to Out-Null; pip writes errors to stderr so they stay visible
    & $pipCmd install --upgrade pip --quiet | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Warn "pip upgrade failed (non-critical, continuing...)"
    }

    Write-Info "Installing $($QuantumPackages.Count) packages (this may take a few minutes)..."
    Write-Host ""

    $failed = @()
    foreach ($pkg in $QuantumPackages) {
        $padded = $pkg.PadRight(30)
        Write-Host "  $padded" -NoNewline

        # Stdout only to Out-Null; pip error messages stay on stderr for debugging
        & $pipCmd install $pkg --quiet | Out-Null

        if ($LASTEXITCODE -eq 0) {
            Write-Host "[OK] installed" -ForegroundColor Green
        }
        else {
            Write-Host "[ERR] failed" -ForegroundColor Red
            $failed += $pkg
        }
    }

    Write-Host ""

    if ($failed.Count -gt 0) {
        Write-Warn "Some packages failed: $($failed -join ', ')"
        Write-Info "You can try installing them manually:"
        Write-Info "  & `"$VenvDir\Scripts\Activate.ps1`""
        Write-Info "  pip install $($failed -join ' ')"
    }
    else {
        Write-Success "All packages installed successfully"
    }

    # Register Jupyter kernel
    Write-Info "Registering Jupyter kernel..."
    # Use a distinct name to avoid shadowing the $pythonCmd returned from Install-Python
    $venvPython = Join-Path $VenvDir "Scripts\python.exe"
    & $venvPython -m ipykernel install --user --name quantum-env `
                  --display-name "Quantum Computing (Python)" | Out-Null

    if ($LASTEXITCODE -eq 0) {
        Write-Success "Jupyter kernel registered"
    }
    else {
        Write-Warn "Failed to register Jupyter kernel (non-critical)"
    }
}

function Set-QuantumEnvironment {
    Write-Step "6/7" "Configuring development environment"

    # Copy VS Code settings (with Windows-specific Python path)
    $vscodeDir = Join-Path $QuantumDir ".vscode"
    if (-not (Test-Path $vscodeDir)) {
        New-Item -ItemType Directory -Path $vscodeDir -Force | Out-Null
    }

    $settingsSrc = Join-Path $ScriptRoot "configs\vscode-settings.json"
    $settingsDst = Join-Path $vscodeDir "settings.json"

    if (Test-Path $settingsSrc) {
        # Read the template and fix the Python interpreter path for Windows.
        # Use plain .NET String.Replace() - no regex involved, no back-reference
        # expansion risk. Simple literal-to-literal swap is the safest approach.
        $settingsContent = Get-Content $settingsSrc -Raw
        $settingsContent = $settingsContent.Replace(
            '"${workspaceFolder}/.venv/bin/python"',
            '"${workspaceFolder}\.venv\Scripts\python.exe"'
        )
        Set-Content -Path $settingsDst -Value $settingsContent -Encoding UTF8
        Write-Success "VS Code settings configured (Windows paths applied)"
    }
    else {
        Write-Warn "VS Code settings template not found at: $settingsSrc"
    }

    # Copy examples
    $examplesSrc = Join-Path $ScriptRoot "examples"
    $examplesDst = Join-Path $QuantumDir "examples"
    if (Test-Path $examplesSrc) {
        if (-not (Test-Path $examplesDst)) {
            New-Item -ItemType Directory -Path $examplesDst -Force | Out-Null
        }
        Copy-Item "$examplesSrc\*" $examplesDst -Force -Recurse
        Write-Success "Example programs copied"
    }
    else {
        Write-Warn "Examples directory not found at: $examplesSrc"
    }

    # Copy verify script
    $verifySrc = Join-Path $ScriptRoot "scripts\verify-setup.py"
    if (Test-Path $verifySrc) {
        Copy-Item $verifySrc (Join-Path $QuantumDir "verify-setup.py") -Force
        Write-Success "Verification script copied"
    }
    else {
        Write-Warn "Verification script not found at: $verifySrc"
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
        # Use single-quote here-string to avoid variable expansion, then
        # replace placeholder tokens with the actual paths. This ensures the
        # profile file contains literal paths (not variables that won't exist
        # when the profile is loaded in a fresh session).
        $profileBlock = @'

# >>> quantum-dev-env >>>
function qenv { & "__VENV_DIR__\Scripts\Activate.ps1" }
function qcd { Set-Location "__QUANTUM_DIR__" }
function qtest { & "__VENV_DIR__\Scripts\python.exe" "__QUANTUM_DIR__\verify-setup.py" }
# <<< quantum-dev-env <<<
'@
        $profileBlock = $profileBlock.Replace("__VENV_DIR__", $VenvDir)
        $profileBlock = $profileBlock.Replace("__QUANTUM_DIR__", $QuantumDir)

        Add-Content -Path $PROFILE -Value $profileBlock
        Write-Success "PowerShell profile functions added (qenv, qcd, qtest)"
    }
    else {
        Write-Info "PowerShell profile already configured"
    }

    # Load functions into the current session so they are available immediately
    Invoke-Expression "function global:qenv { & `"$VenvDir\Scripts\Activate.ps1`" }"
    Invoke-Expression "function global:qcd { Set-Location `"$QuantumDir`" }"
    Invoke-Expression "function global:qtest { & `"$VenvDir\Scripts\python.exe`" `"$QuantumDir\verify-setup.py`" }"
}

function Invoke-Verification {
    Write-Step "7/7" "Verifying installation"

    $pythonCmd = Join-Path $VenvDir "Scripts\python.exe"
    $verifyScript = Join-Path $QuantumDir "verify-setup.py"

    if (-not (Test-Path $pythonCmd)) {
        Write-Warn "Python not found at: $pythonCmd"
        Write-Info "Virtual environment may not be set up correctly"
        return
    }

    if (Test-Path $verifyScript) {
        & $pythonCmd $verifyScript
        if ($LASTEXITCODE -ne 0) {
            Write-Warn "Some verification checks failed (see above)"
        }
    }
    else {
        Write-Warn "Verification script not found at: $verifyScript"
    }
}

function Show-SuccessMessage {
    Write-Banner "Quantum Dev Environment Ready!"

    Write-Host "Your quantum computing environment is set up!" -ForegroundColor Green
    Write-Host ""
    Write-Host "  Project directory: $QuantumDir" -ForegroundColor Cyan
    Write-Host "  Virtual environment: $VenvDir" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "===========================================================" -ForegroundColor Red
    Write-Host " IMPORTANT: Restart your terminal before using the commands! " -ForegroundColor Yellow
    Write-Host "===========================================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Quick Start:" -ForegroundColor White
    Write-Host "  qenv          -> Activate the quantum environment" -ForegroundColor Yellow
    Write-Host "  qcd           -> Navigate to the quantum directory" -ForegroundColor Yellow
    Write-Host "  qtest         -> Verify your installation" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Run an example:" -ForegroundColor White
    Write-Host "  qenv" -ForegroundColor Yellow
    Write-Host "  python examples\01-hello-quantum.py" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Start Jupyter:" -ForegroundColor White
    Write-Host "  qenv" -ForegroundColor Yellow
    Write-Host "  jupyter notebook" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Happy quantum computing!" -ForegroundColor Magenta
}

# ==============================================================================
# Main
# ==============================================================================

if ($Help) {
    Show-Help
    exit 0
}

Write-Banner "Quantum Dev Environment - Windows Installer"

# Check PowerShell version
if ($PSVersionTable.PSVersion.Major -lt 5) {
    Write-Error2 "PowerShell 5.1 or higher is required"
    Write-Info "Current version: $($PSVersionTable.PSVersion)"
    Write-Info "Update PowerShell: https://aka.ms/powershell"
    exit 1
}

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

Get-InstallConfirmation

if (-not (Test-InternetConnection)) {
    exit 1
}

$startTime = Get-Date
$pythonCmd = Install-Python
Install-Git
Install-VSCode
Initialize-Project -PythonCmd $pythonCmd
Install-QuantumPackages
Set-QuantumEnvironment
Invoke-Verification

$elapsed = (Get-Date) - $startTime
$totalMins = [int]$elapsed.TotalMinutes
$secs = $elapsed.Seconds
Write-Info "Installation completed in ${totalMins}m ${secs}s"

Show-SuccessMessage
