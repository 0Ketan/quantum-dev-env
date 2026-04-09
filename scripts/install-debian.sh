#!/bin/bash
# ==============================================================================
# install-debian.sh - Quantum dev environment installer for Debian-based Linux
# ==============================================================================
# Supports: Ubuntu, Debian, Linux Mint, Pop!_OS, Elementary OS
#
# This script installs all system packages and Python dependencies needed for
# quantum computing development, creates a virtual environment, configures
# VS Code, and sets up shell aliases.
#
# Usage:
#   ./install-debian.sh           # Interactive installation
#   ./install-debian.sh --yes     # Skip confirmation prompts
#   ./install-debian.sh --help    # Show help
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common-functions.sh"

# ==============================================================================
# Configuration
# ==============================================================================

AUTO_YES=false

SYSTEM_PACKAGES=(
    "python3"
    "python3-pip"
    "python3-venv"
    "python3-dev"
    "git"
    "build-essential"
    "gfortran"
    "cmake"
    "libblas-dev"
    "liblapack-dev"
    "python3-tk"
    "curl"
)

# ==============================================================================
# Functions
# ==============================================================================

show_help() {
    cat << 'EOF'
Usage: install-debian.sh [OPTIONS]

Install quantum computing development environment on Debian-based Linux.

Options:
  --yes       Skip confirmation prompts (auto-accept)
  --dir DIR   Set quantum project directory (default: ~/quantum)
  --help      Show this help message

Supported distributions:
  Ubuntu, Debian, Linux Mint, Pop!_OS, Elementary OS

What gets installed:
  System: python3, pip, git, VS Code, build tools
  Python: qiskit, cirq, pennylane, jupyter, numpy, matplotlib, scipy
EOF
}

# Confirm before proceeding (unless --yes is set)
confirm_install() {
    if "$AUTO_YES"; then
        return 0
    fi

    echo -e "${BOLD}The following will be installed:${NC}"
    echo ""
    echo "  📦 System packages: ${SYSTEM_PACKAGES[*]}"
    echo "  🐍 Python packages: ${QUANTUM_PACKAGES[*]}"
    echo "  📂 Project directory: $QUANTUM_DIR"
    echo "  🖥️  VS Code (if not installed)"
    echo ""
    read -rp "Proceed with installation? (Y/n): " choice
    case "$choice" in
        [Nn]*) print_info "Installation cancelled"; exit 0 ;;
        *) return 0 ;;
    esac
}

# Update system packages
update_system() {
    print_step "1/7" "Updating system packages"
    print_info "Running apt update && apt upgrade..."

    if sudo apt update -y 2>&1 | tail -3; then
        print_success "Package lists updated"
    else
        print_warning "Package list update had warnings (continuing...)"
    fi

    if sudo apt upgrade -y 2>&1 | tail -3; then
        print_success "System packages upgraded"
    else
        print_warning "System upgrade had warnings (continuing...)"
    fi
}

# Install system-level packages
install_system_packages() {
    print_step "2/7" "Installing system packages"

    local to_install=()
    for pkg in "${SYSTEM_PACKAGES[@]}"; do
        if dpkg -l "$pkg" 2>/dev/null | grep -q "^ii"; then
            print_info "$pkg is already installed"
        else
            to_install+=("$pkg")
        fi
    done

    if [[ ${#to_install[@]} -gt 0 ]]; then
        print_info "Installing: ${to_install[*]}"
        if sudo apt install -y "${to_install[@]}"; then
            print_success "System packages installed"
        else
            print_error "Failed to install some system packages"
            return 1
        fi
    else
        print_success "All system packages already installed"
    fi
}

# Install VS Code
install_vscode() {
    print_step "3/7" "Installing VS Code"

    if check_command code; then
        print_success "VS Code is already installed"
        return 0
    fi

    print_info "Installing VS Code via Microsoft repository..."

    # Install dependencies
    sudo apt install -y apt-transport-https wget gpg 2>/dev/null || true

    # Add Microsoft GPG key
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc \
        | gpg --dearmor \
        | sudo tee /usr/share/keyrings/packages.microsoft.gpg >/dev/null 2>&1

    # Add VS Code repository
    echo "deb [arch=amd64,arm64,armhf signed-by=/usr/share/keyrings/packages.microsoft.gpg] \
https://packages.microsoft.com/repos/code stable main" \
        | sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null

    # Install VS Code
    sudo apt update -y 2>/dev/null
    if sudo apt install -y code; then
        print_success "VS Code installed"
    else
        print_warning "Could not install VS Code automatically"
        print_info "Install manually: https://code.visualstudio.com/"
        print_info "Or via snap: sudo snap install code --classic"
    fi
}

# Set up the quantum project directory and virtual environment
setup_project() {
    print_step "4/7" "Setting up project directory"

    create_directory "$QUANTUM_DIR"

    local python_cmd
    python_cmd=$(get_python_cmd)
    if [[ -z "$python_cmd" ]]; then
        print_error "Python 3 not found after installation"
        return 1
    fi

    validate_python_version "$python_cmd"
    create_venv "$python_cmd" "$VENV_DIR"
}

# Install Python packages
install_python_packages() {
    print_step "5/7" "Installing quantum computing packages"
    install_packages "$VENV_DIR" "${QUANTUM_PACKAGES[@]}"
    register_jupyter_kernel "$VENV_DIR"
}

# Configure VS Code and copy project files
configure_environment() {
    print_step "6/7" "Configuring development environment"

    setup_vscode "$SCRIPT_DIR" "$QUANTUM_DIR"
    copy_examples "$SCRIPT_DIR" "$QUANTUM_DIR"
    copy_verify_script "$SCRIPT_DIR" "$QUANTUM_DIR"
    setup_shell_aliases "$SCRIPT_DIR"
}

# Run the verification script
run_verification() {
    print_step "7/7" "Verifying installation"

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

    print_banner "🚀 Quantum Dev Environment - Debian/Ubuntu Installer"

    local distro_name
    distro_name=$(get_distro_name)
    print_info "Detected: $distro_name"
    echo ""

    confirm_install
    check_internet

    local start_time
    start_time=$(date +%s)

    update_system
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
