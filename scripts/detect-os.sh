#!/bin/bash
# ==============================================================================
# detect-os.sh - Detect the operating system and validate system requirements
# ==============================================================================
# This script detects the host operating system (Arch-based, Debian-based,
# Fedora-based, or Windows/WSL) and checks for system-level dependencies
# required to set up the quantum development environment.
#
# Usage:
#   ./detect-os.sh          # Print detected OS type
#   ./detect-os.sh --check  # Print OS and run dependency checks
#
# Exit codes:
#   0 - OS detected and all checks pass
#   1 - Unknown OS or missing critical dependencies
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Source common functions if available
if [[ -f "${SCRIPT_DIR}/common-functions.sh" ]]; then
    source "${SCRIPT_DIR}/common-functions.sh"
else
    # Fallback minimal output functions
    print_success() { echo "[OK] $*"; }
    print_error() { echo "[ERROR] $*" >&2; }
    print_info() { echo "[INFO] $*"; }
    print_warning() { echo "[WARN] $*"; }
    print_banner() { echo "=== $* ==="; }
    print_step() { echo "[$1] $2"; }
    check_command() { command -v "$1" &>/dev/null; }
    detect_shell() { basename "${SHELL:-/bin/bash}"; }
    get_python_cmd() {
        if command -v python3 &>/dev/null; then echo "python3";
        elif command -v python &>/dev/null; then echo "python";
        else echo ""; fi
    }
    validate_python_version() { "$1" --version; return 0; }
    get_distro_name() {
        if [[ -f /etc/os-release ]]; then
            grep -oP '^PRETTY_NAME=\K.*' /etc/os-release | tr -d '"'
        else uname -s; fi
    }
fi

# ==============================================================================
# OS Detection
# ==============================================================================

# Detect the operating system family
# Returns: arch, debian, fedora, windows, or unknown
detect_os() {
    # Check for Windows (Git Bash, MSYS, Cygwin, or WSL)
    if [[ "${OS:-}" == "Windows_NT" ]] || uname -r 2>/dev/null | grep -qi microsoft; then
        if uname -r 2>/dev/null | grep -qi microsoft; then
            echo "wsl"
        else
            echo "windows"
        fi
        return 0
    fi

    # Check for macOS
    if [[ "$(uname -s)" == "Darwin" ]]; then
        echo "macos"
        return 0
    fi

    # Linux detection via /etc/os-release
    if [[ -f /etc/os-release ]]; then
        local id id_like
        id=$(grep -oP '^ID=\K.*' /etc/os-release | tr -d '"')
        id_like=$(grep -oP '^ID_LIKE=\K.*' /etc/os-release 2>/dev/null | tr -d '"' || echo "")

        # Arch-based: Arch, Manjaro, CachyOS, Garuda, EndeavourOS
        if [[ "$id" == "arch" ]] || echo "$id_like" | grep -q "arch"; then
            echo "arch"
            return 0
        fi

        # Debian-based: Ubuntu, Debian, Linux Mint, Pop!_OS
        if [[ "$id" == "debian" || "$id" == "ubuntu" ]] || \
           echo "$id_like" | grep -qE "(debian|ubuntu)"; then
            echo "debian"
            return 0
        fi

        # Fedora-based: Fedora, CentOS, RHEL
        if [[ "$id" == "fedora" ]] || echo "$id_like" | grep -q "fedora"; then
            echo "fedora"
            return 0
        fi

        # openSUSE
        if [[ "$id" == "opensuse"* ]] || echo "$id_like" | grep -q "suse"; then
            echo "suse"
            return 0
        fi
    fi

    # Fallback: check package managers
    if check_command pacman; then
        echo "arch"
        return 0
    elif check_command apt; then
        echo "debian"
        return 0
    elif check_command dnf; then
        echo "fedora"
        return 0
    fi

    echo "unknown"
    return 1
}

# get_distro_name is defined in common-functions.sh
# (fallback definition is in the else block above)

# ==============================================================================
# Dependency Checks
# ==============================================================================

# Check for required system dependencies
check_dependencies() {
    local os_type="$1"
    local errors=0

    print_info "Checking system dependencies..."
    echo ""

    # Check Python
    local python_cmd
    python_cmd=$(get_python_cmd)
    if [[ -n "$python_cmd" ]]; then
        local py_version
        py_version=$($python_cmd --version 2>&1)
        print_success "Python found: $py_version"

        if ! validate_python_version "$python_cmd"; then
            errors=$((errors + 1))
        fi
    else
        print_error "Python 3 not found"
        case "$os_type" in
            arch)   print_info "Install with: sudo pacman -S python" ;;
            debian) print_info "Install with: sudo apt install python3" ;;
            fedora) print_info "Install with: sudo dnf install python3" ;;
        esac
        errors=$((errors + 1))
    fi

    # Check pip
    if [[ -n "$python_cmd" ]] && "$python_cmd" -m pip --version &>/dev/null; then
        print_success "pip found: $($python_cmd -m pip --version 2>&1 | head -1)"
    else
        print_error "pip not found"
        case "$os_type" in
            arch)   print_info "Install with: sudo pacman -S python-pip" ;;
            debian) print_info "Install with: sudo apt install python3-pip" ;;
            fedora) print_info "Install with: sudo dnf install python3-pip" ;;
        esac
        errors=$((errors + 1))
    fi

    # Check venv module
    if [[ -n "$python_cmd" ]] && "$python_cmd" -m venv --help &>/dev/null; then
        print_success "Python venv module available"
    else
        print_error "Python venv module not found"
        case "$os_type" in
            debian) print_info "Install with: sudo apt install python3-venv" ;;
            *)      print_info "The venv module should be included with Python" ;;
        esac
        errors=$((errors + 1))
    fi

    # Check git
    if check_command git; then
        print_success "Git found: $(git --version)"
    else
        print_warning "Git not found (optional but recommended)"
    fi

    # Check curl or wget
    if check_command curl; then
        print_success "curl found"
    elif check_command wget; then
        print_success "wget found"
    else
        print_warning "Neither curl nor wget found (needed for downloads)"
    fi

    echo ""
    return "$errors"
}

# ==============================================================================
# Main
# ==============================================================================

show_help() {
    cat << 'EOF'
Usage: detect-os.sh [OPTIONS]

Detect the operating system and validate system requirements.

Options:
  --check     Run dependency checks after detection
  --json      Output result as JSON
  --quiet     Only output the OS type string
  --help      Show this help message

Examples:
  ./detect-os.sh            # Print detected OS info
  ./detect-os.sh --check    # Detect OS and check dependencies
  ./detect-os.sh --quiet    # Print only: arch, debian, fedora, etc.
EOF
}

main() {
    local do_check=false
    local quiet=false
    local json=false

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --check) do_check=true ;;
            --quiet) quiet=true ;;
            --json)  json=true ;;
            --help)  show_help; exit 0 ;;
            *)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
        shift
    done

    local os_type distro_name
    os_type=$(detect_os) || true
    distro_name=$(get_distro_name)

    if "$quiet"; then
        echo "$os_type"
        exit 0
    fi

    if "$json"; then
        local python_cmd
        python_cmd=$(get_python_cmd)
        local py_ver="null"
        if [[ -n "$python_cmd" ]]; then
            py_ver="\"$($python_cmd --version 2>&1)\""
        fi
        cat << EOF
{
  "os_type": "$os_type",
  "distro": "$distro_name",
  "kernel": "$(uname -r)",
  "arch": "$(uname -m)",
  "python": $py_ver,
  "shell": "$(detect_shell)"
}
EOF
        exit 0
    fi

    print_banner "🔍 System Detection"

    echo -e "  ${BOLD}OS Type:${NC}      $os_type"
    echo -e "  ${BOLD}Distribution:${NC} $distro_name"
    echo -e "  ${BOLD}Kernel:${NC}       $(uname -r)"
    echo -e "  ${BOLD}Architecture:${NC} $(uname -m)"
    echo -e "  ${BOLD}Shell:${NC}        $(detect_shell)"
    echo ""

    if [[ "$os_type" == "unknown" ]]; then
        print_error "Could not detect your operating system"
        print_info "Supported systems: Arch-based, Debian-based, Fedora-based"
        print_info "Please see docs/ for manual installation instructions"
        exit 1
    fi

    if "$do_check"; then
        local exit_code=0
        check_dependencies "$os_type" || exit_code=$?
        if [[ $exit_code -eq 0 ]]; then
            echo ""
            print_success "All dependency checks passed!"
        else
            echo ""
            print_warning "$exit_code dependency issue(s) found"
            print_info "The installer may attempt to install missing dependencies"
        fi
    fi
}

main "$@"
