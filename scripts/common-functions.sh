#!/bin/bash
# ==============================================================================
# common-functions.sh - Shared utility functions for quantum-dev-env installers
# ==============================================================================
# This file provides colored output helpers, command checks, directory creation,
# and other shared utilities used across all installer scripts.
#
# Usage: source this file from other scripts
#   source "$(dirname "$0")/common-functions.sh"
# ==============================================================================

# Strict mode
set -euo pipefail

# ------------------------------------------------------------------------------
# Color codes
# ------------------------------------------------------------------------------
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly MAGENTA='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'  # No Color

# ------------------------------------------------------------------------------
# Quantum directory defaults
# ------------------------------------------------------------------------------
QUANTUM_DIR="${QUANTUM_DIR:-$HOME/quantum}"
VENV_DIR="${QUANTUM_DIR}/.venv"

# ------------------------------------------------------------------------------
# Quantum packages to install
# ------------------------------------------------------------------------------
QUANTUM_PACKAGES=(
    "qiskit"
    "qiskit-aer"
    "qiskit-ibm-runtime"
    "cirq"
    "pennylane"
    "numpy"
    "matplotlib"
    "scipy"
    "jupyter"
    "ipykernel"
)

# ==============================================================================
# Output Functions
# ==============================================================================

# Print a success message in green with a checkmark
# Arguments: message string
print_success() {
    echo -e "${GREEN}✅ $*${NC}"
}

# Print an error message in red with a cross
# Arguments: message string
print_error() {
    echo -e "${RED}❌ $*${NC}" >&2
}

# Print an informational message in blue
# Arguments: message string
print_info() {
    echo -e "${BLUE}ℹ️  $*${NC}"
}

# Print a warning message in yellow
# Arguments: message string
print_warning() {
    echo -e "${YELLOW}⚠️  $*${NC}"
}

# Print a step header in bold magenta
# Arguments: step number, message string
print_step() {
    local step_num="$1"
    shift
    echo ""
    echo -e "${MAGENTA}${BOLD}[$step_num] $*${NC}"
    echo -e "${MAGENTA}$(printf '%.0s─' {1..60})${NC}"
}

# Print a section banner
# Arguments: message string
print_banner() {
    local msg="$*"
    local len=${#msg}
    local border
    border=$(printf '%.0s═' $(seq 1 $((len + 4))))
    echo ""
    echo -e "${CYAN}${BOLD}╔${border}╗${NC}"
    echo -e "${CYAN}${BOLD}║  ${msg}  ║${NC}"
    echo -e "${CYAN}${BOLD}╚${border}╝${NC}"
    echo ""
}

# ==============================================================================
# Utility Functions
# ==============================================================================

# Check if a command exists on the system
# Arguments: command name
# Returns: 0 if exists, 1 if not
check_command() {
    local cmd="$1"
    if command -v "$cmd" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Create a directory with error handling
# Arguments: directory path
create_directory() {
    local dir="$1"
    if [[ -d "$dir" ]]; then
        print_info "Directory already exists: $dir"
    else
        if mkdir -p "$dir" 2>/dev/null; then
            print_success "Created directory: $dir"
        else
            print_error "Failed to create directory: $dir"
            return 1
        fi
    fi
}

# Check for internet connectivity
# Returns: 0 if connected, 1 if not
check_internet() {
    print_info "Checking internet connectivity..."
    if curl -s --max-time 5 https://pypi.org >/dev/null 2>&1; then
        print_success "Internet connection verified"
        return 0
    elif ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1; then
        print_success "Internet connection verified (via ping)"
        return 0
    else
        print_error "No internet connection detected"
        print_info "Please check your network and try again"
        return 1
    fi
}

# Get the Python 3 command available on the system
# Returns: python command name via stdout
get_python_cmd() {
    if check_command python3; then
        echo "python3"
    elif check_command python; then
        # Verify it's Python 3
        local ver
        ver=$(python --version 2>&1 | grep -oP '\d+' | head -1)
        if [[ "$ver" -ge 3 ]]; then
            echo "python"
        else
            echo ""
        fi
    else
        echo ""
    fi
}

# Validate that Python version is 3.8 or higher
# Arguments: python command
# Returns: 0 if valid, 1 if not
validate_python_version() {
    local python_cmd="$1"
    local version
    version=$($python_cmd --version 2>&1 | grep -oP '\d+\.\d+' | head -1)
    local major minor
    major=$(echo "$version" | cut -d. -f1)
    minor=$(echo "$version" | cut -d. -f2)

    if [[ "$major" -ge 3 && "$minor" -ge 8 ]]; then
        print_success "Python $version detected (>= 3.8 required)"
        return 0
    else
        print_error "Python $version detected, but >= 3.8 is required"
        return 1
    fi
}

# Create a Python virtual environment
# Arguments: python command, venv directory
create_venv() {
    local python_cmd="$1"
    local venv_path="$2"

    if [[ -d "$venv_path" ]]; then
        print_warning "Virtual environment already exists at: $venv_path"
        read -rp "Recreate it? (y/N): " recreate
        if [[ "$recreate" =~ ^[Yy]$ ]]; then
            rm -rf "$venv_path"
        else
            print_info "Keeping existing virtual environment"
            return 0
        fi
    fi

    print_info "Creating virtual environment at: $venv_path"
    if "$python_cmd" -m venv "$venv_path"; then
        print_success "Virtual environment created"
    else
        print_error "Failed to create virtual environment"
        return 1
    fi
}

# Install Python packages in the virtual environment
# Arguments: venv directory, packages array
install_packages() {
    local venv_path="$1"
    shift
    local packages=("$@")
    local pip_cmd="${venv_path}/bin/pip"

    print_info "Upgrading pip..."
    "$pip_cmd" install --upgrade pip --quiet 2>/dev/null || true

    print_info "Installing ${#packages[@]} packages (this may take a few minutes)..."
    echo ""

    local failed=()
    for pkg in "${packages[@]}"; do
        printf "  %-30s" "$pkg"
        if "$pip_cmd" install "$pkg" --quiet 2>/dev/null; then
            echo -e "${GREEN}✅ installed${NC}"
        else
            echo -e "${RED}❌ failed${NC}"
            failed+=("$pkg")
        fi
    done
    echo ""

    if [[ ${#failed[@]} -gt 0 ]]; then
        print_warning "Some packages failed to install: ${failed[*]}"
        print_info "You can try installing them manually:"
        print_info "  source ${venv_path}/bin/activate"
        print_info "  pip install ${failed[*]}"
        return 1
    else
        print_success "All packages installed successfully"
        return 0
    fi
}

# Register a Jupyter kernel for the virtual environment
# Arguments: venv directory
register_jupyter_kernel() {
    local venv_path="$1"
    local python_cmd="${venv_path}/bin/python"

    print_info "Registering Jupyter kernel..."
    if "$python_cmd" -m ipykernel install --user \
        --name quantum-env \
        --display-name "Quantum Computing (Python)" \
        2>/dev/null; then
        print_success "Jupyter kernel registered: 'Quantum Computing (Python)'"
    else
        print_warning "Failed to register Jupyter kernel (non-critical)"
    fi
}

# Detect the user's current shell
# Returns: shell name via stdout (bash, zsh, fish, or unknown)
detect_shell() {
    local shell_name
    shell_name=$(basename "${SHELL:-/bin/bash}")
    echo "$shell_name"
}

# Get the distribution pretty name from /etc/os-release
# Returns: distro name string via stdout
get_distro_name() {
    if [[ -f /etc/os-release ]]; then
        grep -oP '^PRETTY_NAME=\K.*' /etc/os-release | tr -d '"'
    else
        uname -s
    fi
}

# Add aliases to the appropriate shell configuration
# Arguments: script directory (where alias files are)
setup_shell_aliases() {
    local script_dir="$1"
    local config_dir
    config_dir="$(dirname "$script_dir")/configs"
    local shell_name
    shell_name=$(detect_shell)

    print_info "Detected shell: $shell_name"

    case "$shell_name" in
        bash)
            local rc_file="$HOME/.bashrc"
            local alias_file="${config_dir}/bash-aliases.sh"
            if [[ -f "$alias_file" ]]; then
                local marker="# >>> quantum-dev-env aliases >>>"
                if ! grep -q "$marker" "$rc_file" 2>/dev/null; then
                    {
                        echo ""
                        echo "$marker"
                        cat "$alias_file"
                        echo "# <<< quantum-dev-env aliases <<<"
                    } >> "$rc_file"
                    print_success "Aliases added to $rc_file"
                else
                    print_info "Aliases already present in $rc_file"
                fi
            fi
            ;;
        zsh)
            local rc_file="$HOME/.zshrc"
            local alias_file="${config_dir}/zsh-aliases.sh"
            if [[ -f "$alias_file" ]]; then
                local marker="# >>> quantum-dev-env aliases >>>"
                if ! grep -q "$marker" "$rc_file" 2>/dev/null; then
                    {
                        echo ""
                        echo "$marker"
                        cat "$alias_file"
                        echo "# <<< quantum-dev-env aliases <<<"
                    } >> "$rc_file"
                    print_success "Aliases added to $rc_file"
                else
                    print_info "Aliases already present in $rc_file"
                fi
            fi
            ;;
        fish)
            local fish_dir="$HOME/.config/fish"
            local alias_file="${config_dir}/fish-aliases.fish"
            if [[ -f "$alias_file" ]]; then
                mkdir -p "$fish_dir/conf.d"
                cp "$alias_file" "$fish_dir/conf.d/quantum-aliases.fish"
                print_success "Aliases added to $fish_dir/conf.d/quantum-aliases.fish"
            fi
            ;;
        *)
            print_warning "Unknown shell: $shell_name"
            print_info "Add these aliases manually to your shell config:"
            print_info "  alias qenv='source ~/quantum/.venv/bin/activate'"
            print_info "  alias qcd='cd ~/quantum'"
            print_info "  alias qtest='python ~/quantum/verify-setup.py'"
            ;;
    esac
}

# Copy VS Code settings to the quantum project directory
# Arguments: script directory, target project directory
setup_vscode() {
    local script_dir="$1"
    local project_dir="$2"
    local config_dir
    config_dir="$(dirname "$script_dir")/configs"
    local vscode_dir="${project_dir}/.vscode"

    create_directory "$vscode_dir"

    if [[ -f "${config_dir}/vscode-settings.json" ]]; then
        cp "${config_dir}/vscode-settings.json" "${vscode_dir}/settings.json"
        print_success "VS Code settings copied to ${vscode_dir}/settings.json"
    else
        print_warning "VS Code settings template not found"
    fi
}

# Copy example files to the quantum project directory
# Arguments: script directory, target project directory
copy_examples() {
    local script_dir="$1"
    local project_dir="$2"
    local examples_src
    examples_src="$(dirname "$script_dir")/examples"
    local examples_dst="${project_dir}/examples"

    create_directory "$examples_dst"

    if [[ -d "$examples_src" ]]; then
        cp "$examples_src"/*.py "$examples_dst/" 2>/dev/null || true
        cp "$examples_src"/README.md "$examples_dst/" 2>/dev/null || true
        print_success "Example programs copied to ${examples_dst}/"
    else
        print_warning "Examples directory not found"
    fi
}

# Copy the verify script to the quantum project directory
# Arguments: script directory, target project directory
copy_verify_script() {
    local script_dir="$1"
    local project_dir="$2"

    if [[ -f "${script_dir}/verify-setup.py" ]]; then
        cp "${script_dir}/verify-setup.py" "${project_dir}/verify-setup.py"
        chmod +x "${project_dir}/verify-setup.py"
        print_success "Verification script copied to ${project_dir}/"
    fi
}

# Display final success message with next steps
show_success_message() {
    local project_dir="$1"

    print_banner "🎉 Quantum Dev Environment Ready!"

    echo -e "${GREEN}${BOLD}Your quantum computing environment is set up!${NC}"
    echo ""
    echo -e "${CYAN}📂 Project directory:${NC} $project_dir"
    echo -e "${CYAN}🐍 Virtual environment:${NC} ${project_dir}/.venv"
    echo ""
    echo -e "${BOLD}Quick Start:${NC}"
    echo -e "  ${YELLOW}qenv${NC}          → Activate the quantum environment"
    echo -e "  ${YELLOW}qcd${NC}           → Navigate to the quantum directory"
    echo -e "  ${YELLOW}qtest${NC}         → Verify your installation"
    echo ""
    echo -e "${BOLD}Run an example:${NC}"
    echo -e "  ${YELLOW}qenv${NC}"
    echo -e "  ${YELLOW}python examples/01-hello-quantum.py${NC}"
    echo ""
    echo -e "${BOLD}Start Jupyter:${NC}"
    echo -e "  ${YELLOW}qenv${NC}"
    echo -e "  ${YELLOW}jupyter notebook${NC}"
    echo ""
    echo -e "${BOLD}Open in VS Code:${NC}"
    echo -e "  ${YELLOW}qcd && code .${NC}"
    echo ""
    echo -e "${CYAN}📖 Documentation:${NC} https://github.com/0Ketan/quantum-dev-env"
    echo -e "${CYAN}🐛 Report issues:${NC} https://github.com/0Ketan/quantum-dev-env/issues"
    echo ""
    echo -e "${MAGENTA}${BOLD}Happy quantum computing! 🚀${NC}"
}

# Handle cleanup on error or Ctrl+C
# Arguments: optional message
cleanup_on_error() {
    local msg="${1:-Installation interrupted}"
    echo ""
    print_error "$msg"
    print_info "Partial installation may exist at: $QUANTUM_DIR"
    print_info "To clean up, run: rm -rf $QUANTUM_DIR"
    exit 1
}

# Set up a trap for Ctrl+C
trap 'cleanup_on_error "Installation cancelled by user (Ctrl+C)"' INT TERM
