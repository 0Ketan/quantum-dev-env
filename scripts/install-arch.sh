#!/bin/bash
# ==============================================================================
# install-arch.sh - Quantum dev environment installer for Arch-based Linux
# ==============================================================================
# Supports: Arch Linux, Manjaro, CachyOS, Garuda, EndeavourOS
#
# This script installs all system packages and Python dependencies needed for
# quantum computing development, creates a virtual environment, configures
# VS Code, and sets up shell aliases.
#
# Usage:
#   ./install-arch.sh           # Interactive installation
#   ./install-arch.sh --yes     # Skip confirmation prompts
#   ./install-arch.sh --help    # Show help
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/common-functions.sh"

# ==============================================================================
# Configuration
# ==============================================================================

AUTO_YES=false

SYSTEM_PACKAGES=(
    "python"
    "python-pip"
    "python-virtualenv"
    "git"
    "base-devel"
    "gcc"
    "gcc-fortran"
    "cmake"
    "blas"
    "lapack"
    "tk"
)

# ==============================================================================
# Functions
# ==============================================================================

show_help() {
    cat << 'EOF'
Usage: install-arch.sh [OPTIONS]

Install quantum computing development environment on Arch-based Linux.

Options:
  --yes       Skip confirmation prompts (auto-accept)
  --dir DIR   Set quantum project directory (default: ~/quantum)
  --help      Show this help message

Supported distributions:
  Arch Linux, Manjaro, CachyOS, Garuda, EndeavourOS

What gets installed:
  System: python, pip, git, VS Code, build tools
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
    print_info "Running pacman -Syu..."

    if sudo pacman -Syu --noconfirm 2>&1 | tail -5; then
        print_success "System updated"
    else
        print_warning "System update had warnings (continuing...)"
    fi
}

# Install system-level packages
install_system_packages() {
    print_step "2/7" "Installing system packages"

    local to_install=()
    for pkg in "${SYSTEM_PACKAGES[@]}"; do
        if pacman -Qi "$pkg" &>/dev/null; then
            print_info "$pkg is already installed"
        else
            to_install+=("$pkg")
        fi
    done

    if [[ ${#to_install[@]} -gt 0 ]]; then
        print_info "Installing: ${to_install[*]}"
        if sudo pacman -S --noconfirm --needed "${to_install[@]}"; then
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

    # Try official bin from AUR (most reliable)
    print_info "Installing VS Code..."
    if check_command yay; then
        yay -S --noconfirm visual-studio-code-bin 2>/dev/null && {
            print_success "VS Code installed via yay"
            return 0
        }
    elif check_command paru; then
        paru -S --noconfirm visual-studio-code-bin 2>/dev/null && {
            print_success "VS Code installed via paru"
            return 0
        }
    fi

    # Fallback: install code-oss from official repos
    if sudo pacman -S --noconfirm code 2>/dev/null; then
        print_success "VS Code OSS installed via pacman"
    else
        print_warning "Could not install VS Code automatically"
        print_info "Install manually: https://code.visualstudio.com/"
        print_info "Or from AUR: yay -S visual-studio-code-bin"
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

    print_banner "🚀 Quantum Dev Environment - Arch Linux Installer"

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
