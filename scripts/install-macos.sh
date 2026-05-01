#!/bin/bash
# ==============================================================================
# install-macos.sh - Quantum dev environment installer for macOS
# ==============================================================================
# Supports: macOS on Apple Silicon (M1/M2/M3/M4) and Intel
#
# This script installs all system packages and Python dependencies needed for
# quantum computing development, creates a virtual environment, configures
# VS Code, and sets up shell aliases.
#
# What it does:
#   1. Installs Homebrew (if not present)
#   2. Installs Python 3.11+, Git, and VS Code via Homebrew
#   3. Creates ~/quantum project directory
#   4. Creates a Python virtual environment (.venv)
#   5. Installs quantum computing packages (Qiskit, Cirq, PennyLane, etc.)
#   6. Configures VS Code settings
#   7. Sets up shell aliases (zsh, bash, or fish)
#   8. Runs verification tests
#
# Usage:
#   ./install-macos.sh           # Interactive installation
#   ./install-macos.sh --yes     # Skip confirmation prompts
#   ./install-macos.sh --help    # Show help
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common-functions.sh"

# ==============================================================================
# Configuration
# ==============================================================================

AUTO_YES=false

BREW_PACKAGES=(
    "python@3.11"
    "git"
    "cmake"
)

BREW_CASK_PACKAGES=(
    "visual-studio-code"
)

# ==============================================================================
# Functions
# ==============================================================================

show_help() {
    cat << 'EOF'
Usage: install-macos.sh [OPTIONS]

Install quantum computing development environment on macOS.

Options:
  --yes       Skip confirmation prompts (auto-accept)
  --dir DIR   Set quantum project directory (default: ~/quantum)
  --help      Show this help message

Supported hardware:
  Apple Silicon (M1, M2, M3, M4)
  Intel Macs

What gets installed:
  System: Python 3.11, pip, git, VS Code, cmake (via Homebrew)
  Python: qiskit, cirq, pennylane, jupyter, numpy, matplotlib, scipy, pandas
EOF
}

# Detect macOS architecture
detect_arch() {
    local arch
    arch=$(uname -m)
    case "$arch" in
        arm64)
            echo "Apple Silicon"
            ;;
        x86_64)
            # Check if running under Rosetta
            if [[ "$(sysctl -n sysctl.proc_translated 2>/dev/null || echo 0)" == "1" ]]; then
                echo "Apple Silicon (Rosetta 2)"
            else
                echo "Intel"
            fi
            ;;
        *)
            echo "Unknown ($arch)"
            ;;
    esac
}

# Confirm before proceeding (unless --yes is set)
confirm_install() {
    if "$AUTO_YES"; then
        return 0
    fi

    local arch_info
    arch_info=$(detect_arch)

    echo -e "${BOLD}The following will be installed:${NC}"
    echo ""
    echo "  🍎 Architecture: $arch_info"
    echo "  🍺 Homebrew packages: ${BREW_PACKAGES[*]}"
    echo "  🍺 Homebrew casks: ${BREW_CASK_PACKAGES[*]}"
    echo "  🐍 Python packages: ${QUANTUM_PACKAGES[*]}"
    echo "  📂 Project directory: $QUANTUM_DIR"
    echo ""
    read -rp "Proceed with installation? (Y/n): " choice
    case "$choice" in
        [Nn]*) print_info "Installation cancelled"; exit 0 ;;
        *) return 0 ;;
    esac
}

# Ensure Xcode Command Line Tools are installed
install_xcode_cli() {
    print_step "1/8" "Checking Xcode Command Line Tools"

    if xcode-select -p &>/dev/null; then
        print_success "Xcode Command Line Tools already installed"
    else
        print_info "Installing Xcode Command Line Tools..."
        print_info "A system dialog may appear — please click 'Install' if prompted"

        # Trigger the install
        xcode-select --install 2>/dev/null || true

        # Wait for installation to complete
        print_info "Waiting for Xcode Command Line Tools installation..."
        local max_wait=300  # 5 minutes
        local elapsed=0
        while ! xcode-select -p &>/dev/null; do
            sleep 5
            elapsed=$((elapsed + 5))
            if [[ $elapsed -ge $max_wait ]]; then
                print_error "Timed out waiting for Xcode Command Line Tools"
                print_info "Please install manually: xcode-select --install"
                print_info "Then re-run this script"
                exit 1
            fi
        done
        print_success "Xcode Command Line Tools installed"
    fi
}

# Install Homebrew if not present
install_homebrew() {
    print_step "2/8" "Checking Homebrew"

    if check_command brew; then
        print_success "Homebrew is already installed: $(brew --version | head -1)"
        print_info "Updating Homebrew..."
        brew update --quiet 2>/dev/null || print_warning "Homebrew update had warnings (continuing...)"
        return 0
    fi

    print_info "Installing Homebrew (this may take a minute)..."

    # Unattended Homebrew install
    NONINTERACTIVE=1 /bin/bash -c \
        "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

    # Add Homebrew to PATH for this session
    local arch
    arch=$(uname -m)
    if [[ "$arch" == "arm64" ]]; then
        # Apple Silicon: Homebrew installs to /opt/homebrew
        eval "$(/opt/homebrew/bin/brew shellenv)"

        # Ensure it persists in shell config
        local shell_name
        shell_name=$(detect_shell)
        local rc_file
        case "$shell_name" in
            zsh)  rc_file="$HOME/.zshrc" ;;
            bash) rc_file="$HOME/.bash_profile" ;;
            *)    rc_file="$HOME/.zshrc" ;;  # Default to zsh on modern macOS
        esac

        if ! grep -q 'brew shellenv' "$rc_file" 2>/dev/null; then
            echo '' >> "$rc_file"
            echo '# Homebrew' >> "$rc_file"
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> "$rc_file"
            print_info "Added Homebrew to PATH in $rc_file"
        fi
    else
        # Intel: Homebrew installs to /usr/local
        eval "$(/usr/local/bin/brew shellenv)" 2>/dev/null || true
    fi

    if check_command brew; then
        print_success "Homebrew installed successfully: $(brew --version | head -1)"
    else
        print_error "Homebrew installation failed"
        print_info "Please install manually: https://brew.sh"
        exit 1
    fi
}

# Install system packages via Homebrew
install_system_packages() {
    print_step "3/8" "Installing system packages via Homebrew"

    local to_install=()
    for pkg in "${BREW_PACKAGES[@]}"; do
        if brew list "$pkg" &>/dev/null; then
            print_info "$pkg is already installed"
        else
            to_install+=("$pkg")
        fi
    done

    if [[ ${#to_install[@]} -gt 0 ]]; then
        print_info "Installing: ${to_install[*]}"
        if brew install "${to_install[@]}"; then
            print_success "Homebrew packages installed"
        else
            print_error "Failed to install some Homebrew packages"
            return 1
        fi
    else
        print_success "All Homebrew packages already installed"
    fi

    # Ensure the Homebrew Python is preferred over the system one
    local brew_python
    brew_python="$(brew --prefix python@3.11 2>/dev/null)/bin/python3.11"
    if [[ -x "$brew_python" ]]; then
        print_success "Python 3.11 available at: $brew_python"
    else
        # Fallback: try generic python3 from Homebrew
        brew_python="$(brew --prefix python@3 2>/dev/null)/bin/python3" || true
        if [[ -x "$brew_python" ]]; then
            print_success "Python 3 available at: $brew_python"
        fi
    fi
}

# Install VS Code via Homebrew Cask
install_vscode() {
    print_step "4/8" "Installing VS Code"

    if check_command code; then
        print_success "VS Code is already installed"
        return 0
    fi

    # Check if the app exists even if 'code' CLI isn't in PATH
    if [[ -d "/Applications/Visual Studio Code.app" ]]; then
        print_success "VS Code app found in /Applications"
        print_info "To enable the 'code' command, open VS Code and run:"
        print_info "  Command Palette → Shell Command: Install 'code' in PATH"
        return 0
    fi

    print_info "Installing VS Code via Homebrew Cask..."
    if brew install --cask visual-studio-code; then
        print_success "VS Code installed"

        # Try to add 'code' to PATH
        local code_bin="/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code"
        if [[ -x "$code_bin" ]]; then
            print_info "VS Code CLI should be available after restarting your terminal"
        fi
    else
        print_warning "Could not install VS Code automatically"
        print_info "Install manually: https://code.visualstudio.com/"
        print_info "Or run: brew install --cask visual-studio-code"
    fi
}

# Determine the best python3 command to use
get_macos_python_cmd() {
    # Prefer Homebrew Python 3.11
    local brew_prefix
    brew_prefix="$(brew --prefix 2>/dev/null || echo "/opt/homebrew")"

    local candidates=(
        "${brew_prefix}/bin/python3.11"
        "${brew_prefix}/bin/python3"
        "python3"
    )

    for cmd in "${candidates[@]}"; do
        if [[ -x "$cmd" ]] || command -v "$cmd" &>/dev/null; then
            echo "$cmd"
            return 0
        fi
    done

    # Fallback to generic detection
    get_python_cmd
}

# Set up the quantum project directory and virtual environment
setup_project() {
    print_step "5/8" "Setting up project directory"

    create_directory "$QUANTUM_DIR"

    local python_cmd
    python_cmd=$(get_macos_python_cmd)
    if [[ -z "$python_cmd" ]]; then
        print_error "Python 3 not found after installation"
        print_info "Try running: brew install python@3.11"
        return 1
    fi

    print_info "Using Python: $python_cmd ($($python_cmd --version 2>&1))"
    validate_python_version "$python_cmd"
    create_venv "$python_cmd" "$VENV_DIR"
}

# Install Python packages
install_python_packages() {
    print_step "6/8" "Installing quantum computing packages"

    # Detect architecture for user info
    local arch_info
    arch_info=$(detect_arch)
    if [[ "$arch_info" == *"Apple Silicon"* ]]; then
        print_info "Apple Silicon detected — using native ARM packages where available"
    fi

    install_packages "$VENV_DIR" "${QUANTUM_PACKAGES[@]}"
    register_jupyter_kernel "$VENV_DIR"
}

# Configure VS Code and copy project files
configure_environment() {
    print_step "7/8" "Configuring development environment"

    setup_vscode "$SCRIPT_DIR" "$QUANTUM_DIR"
    copy_examples "$SCRIPT_DIR" "$QUANTUM_DIR"
    copy_verify_script "$SCRIPT_DIR" "$QUANTUM_DIR"
    setup_shell_aliases "$SCRIPT_DIR"
}

# Run the verification script
run_verification() {
    print_step "8/8" "Verifying installation"

    local python_cmd="${VENV_DIR}/bin/python"
    local verify_script="${QUANTUM_DIR}/verify-setup.py"

    if [[ -f "$verify_script" ]]; then
        if "$python_cmd" "$verify_script"; then
            return 0
        else
            print_warning "Some verification checks failed (see above)"
            return 0  # Non-critical
        fi
    else
        print_warning "Verification script not found"
    fi
}

# ==============================================================================
# Main
# ==============================================================================

main() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --yes)  AUTO_YES=true ;;
            --dir)  QUANTUM_DIR="$2"; VENV_DIR="${QUANTUM_DIR}/.venv"; shift ;;
            --help) show_help; exit 0 ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
        shift
    done

    # Verify we're running on macOS
    if [[ "$(uname -s)" != "Darwin" ]]; then
        print_error "This installer is for macOS only"
        print_info "Detected OS: $(uname -s)"
        print_info "Please use the appropriate installer for your platform"
        exit 1
    fi

    print_banner "🚀 Quantum Dev Environment - macOS Installer"

    local distro_name arch_info
    distro_name=$(get_distro_name)
    arch_info=$(detect_arch)
    print_info "Detected: $distro_name ($arch_info)"
    echo ""

    confirm_install
    check_internet

    local start_time
    start_time=$(date +%s)

    install_xcode_cli
    install_homebrew
    install_system_packages
    install_vscode
    setup_project
    install_python_packages
    configure_environment
    run_verification

    local end_time elapsed
    end_time=$(date +%s)
    elapsed=$(( end_time - start_time ))
    print_info "Installation completed in $((elapsed / 60))m $((elapsed % 60))s"

    show_success_message "$QUANTUM_DIR"
}

main "$@"
