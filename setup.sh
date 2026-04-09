#!/bin/bash
# ==============================================================================
# setup.sh - One-command quantum computing environment installer
# ==============================================================================
#
#  ██████╗ ██╗   ██╗ █████╗ ███╗   ██╗████████╗██╗   ██╗███╗   ███╗
# ██╔═══██╗██║   ██║██╔══██╗████╗  ██║╚══██╔══╝██║   ██║████╗ ████║
# ██║   ██║██║   ██║███████║██╔██╗ ██║   ██║   ██║   ██║██╔████╔██║
# ██║▄▄ ██║██║   ██║██╔══██║██║╚██╗██║   ██║   ██║   ██║██║╚██╔╝██║
# ╚██████╔╝╚██████╔╝██║  ██║██║ ╚████║   ██║   ╚██████╔╝██║ ╚═╝ ██║
#  ╚══▀▀═╝  ╚═════╝ ╚═╝  ╚═╝╚═╝  ╚═══╝   ╚═╝    ╚═════╝ ╚═╝     ╚═╝
#
#  Quantum Computing Development Environment Setup
#
# This script automatically detects your operating system and runs
# the appropriate installer for your quantum computing dev environment.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/your-username/quantum-dev-env/main/setup.sh | bash
#   # or
#   git clone https://github.com/your-username/quantum-dev-env.git
#   cd quantum-dev-env && ./setup.sh
#
# Options:
#   --yes       Skip confirmation prompts
#   --dir DIR   Set quantum project directory (default: ~/quantum)
#   --help      Show help
# ==============================================================================

set -euo pipefail

# ==============================================================================
# Resolve script directory
# ==============================================================================

# If running from a pipe (curl | bash), we need to clone the repo first
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}" 2>/dev/null)" 2>/dev/null && pwd)" || SCRIPT_DIR=""

if [[ -z "$SCRIPT_DIR" || ! -f "${SCRIPT_DIR}/scripts/common-functions.sh" ]]; then
    # Running from pipe - need to clone the repo
    TEMP_DIR=$(mktemp -d)
    echo "📥 Downloading quantum-dev-env..."
    if git clone --depth 1 https://github.com/your-username/quantum-dev-env.git "$TEMP_DIR/quantum-dev-env" 2>/dev/null; then
        SCRIPT_DIR="$TEMP_DIR/quantum-dev-env"
    else
        echo "❌ Failed to download quantum-dev-env"
        echo "   Please clone manually:"
        echo "   git clone https://github.com/your-username/quantum-dev-env.git"
        echo "   cd quantum-dev-env && ./setup.sh"
        exit 1
    fi
    # Clean up temp dir on exit
    trap "rm -rf $TEMP_DIR" EXIT
fi

# ==============================================================================
# Source common functions
# ==============================================================================

source "${SCRIPT_DIR}/scripts/common-functions.sh"

# ==============================================================================
# Parse arguments
# ==============================================================================

PASSTHROUGH_ARGS=()

show_help() {
    cat << 'EOF'
Usage: setup.sh [OPTIONS]

🚀 One-command quantum computing development environment setup.

Options:
  --yes       Skip confirmation prompts (auto-accept)
  --dir DIR   Set quantum project directory (default: ~/quantum)
  --help      Show this help message

Supported platforms:
  🐧 Arch-based Linux (Arch, Manjaro, CachyOS, Garuda)
  🐧 Debian-based Linux (Ubuntu, Debian, Linux Mint)
  🪟 Windows 10/11 (via PowerShell - see docs/windows.md)

Quick start:
  git clone https://github.com/your-username/quantum-dev-env.git
  cd quantum-dev-env
  ./setup.sh

For more information:
  https://github.com/your-username/quantum-dev-env
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --help|-h) show_help; exit 0 ;;
        --yes)     PASSTHROUGH_ARGS+=("--yes") ;;
        --dir)     PASSTHROUGH_ARGS+=("--dir" "$2"); shift ;;
        *)
            print_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
    shift
done

# ==============================================================================
# ASCII Art Banner
# ==============================================================================

show_welcome() {
    echo ""
    echo -e "${CYAN}${BOLD}"
    cat << 'BANNER'
  ╔══════════════════════════════════════════════════════════╗
  ║                                                          ║
  ║   ⚛️  Quantum Computing Dev Environment Setup  ⚛️        ║
  ║                                                          ║
  ║   One command to rule them all.                          ║
  ║   Sets up Qiskit, Cirq, PennyLane & more.               ║
  ║                                                          ║
  ╚══════════════════════════════════════════════════════════╝
BANNER
    echo -e "${NC}"
}

# ==============================================================================
# Main Logic
# ==============================================================================

main() {
    show_welcome

    # Step 1: Detect OS
    print_step "1/3" "Detecting your operating system"

    local os_type
    os_type=$("${SCRIPT_DIR}/scripts/detect-os.sh" --quiet) || os_type="unknown"

    local distro_name
    distro_name=$(grep -oP '^PRETTY_NAME=\K.*' /etc/os-release 2>/dev/null \
                  | tr -d '"' || echo "Unknown")

    echo -e "  ${BOLD}Detected:${NC} $distro_name"
    echo -e "  ${BOLD}OS Type:${NC}  $os_type"
    echo ""

    # Step 2: Select and run installer
    print_step "2/3" "Running platform-specific installer"

    case "$os_type" in
        arch)
            print_info "Using Arch-based installer (pacman)"
            bash "${SCRIPT_DIR}/scripts/install-arch.sh" "${PASSTHROUGH_ARGS[@]+"${PASSTHROUGH_ARGS[@]}"}"
            ;;
        debian)
            print_info "Using Debian-based installer (apt)"
            bash "${SCRIPT_DIR}/scripts/install-debian.sh" "${PASSTHROUGH_ARGS[@]+"${PASSTHROUGH_ARGS[@]}"}"
            ;;
        fedora)
            print_error "Fedora-based installer is not yet available"
            print_info "Please see docs/troubleshooting.md for manual installation"
            print_info "Want to contribute? See docs/contributing.md"
            exit 1
            ;;
        wsl)
            print_info "WSL detected - using Debian-based installer"
            print_info "For native Windows, use scripts/install-windows.ps1"
            bash "${SCRIPT_DIR}/scripts/install-debian.sh" "${PASSTHROUGH_ARGS[@]+"${PASSTHROUGH_ARGS[@]}"}"
            ;;
        windows)
            print_error "Windows detected via Git Bash/MSYS"
            print_info "Please use PowerShell instead:"
            echo ""
            echo -e "  ${YELLOW}powershell -ExecutionPolicy Bypass -File scripts/install-windows.ps1${NC}"
            echo ""
            print_info "Or see: docs/windows.md"
            exit 1
            ;;
        macos)
            print_error "macOS is not currently supported"
            print_info "macOS support is planned for a future release"
            print_info "Want to contribute? See docs/contributing.md"
            exit 1
            ;;
        *)
            print_error "Could not detect your operating system"
            echo ""
            print_info "Supported platforms:"
            echo "  • Arch-based (Arch, Manjaro, CachyOS, Garuda)"
            echo "  • Debian-based (Ubuntu, Debian, Linux Mint)"
            echo "  • Windows 10/11 (use install-windows.ps1)"
            echo ""
            print_info "For manual installation, see the docs/ directory"
            exit 1
            ;;
    esac

    # Step 3: Done!
    print_step "3/3" "Setup complete"
    print_info "Restart your terminal or run: source ~/.bashrc"
    print_info "Then type 'qenv' to activate your quantum environment"
    echo ""
}

main
