# 🤝 Contributing to quantum-dev-env

Thank you for your interest in contributing! This guide will help you get started.

---

## How to Contribute

### 🐛 Reporting Bugs

1. **Search existing issues** first to avoid duplicates
2. Use the [bug report template](../.github/ISSUE_TEMPLATE/bug_report.md)
3. Include:
   - Operating system and version
   - Python version
   - Full error message and logs
   - Steps to reproduce
   - Screenshots if applicable

### 💡 Suggesting Features

1. Use the [feature request template](../.github/ISSUE_TEMPLATE/feature_request.md)
2. Describe:
   - What problem the feature solves
   - Your proposed solution
   - Any alternatives you've considered

### 📝 Submitting Pull Requests

1. **Fork** the repository
2. **Create a branch** for your changes:
   ```bash
   git checkout -b feature/your-feature-name
   ```
3. **Make your changes** following the code style guidelines below
4. **Test** your changes on at least one supported platform
5. **Commit** with clear, descriptive messages:
   ```bash
   git commit -m "feat: add support for Fedora-based distros"
   ```
6. **Push** to your fork and open a PR

---

## Code Style Guidelines

### Bash Scripts

- Use `#!/bin/bash` shebang
- Enable strict mode: `set -euo pipefail`
- Use `shellcheck`-compliant code
- Follow these conventions:
  ```bash
  # Variables: UPPER_CASE for constants, lower_case for locals
  readonly MY_CONSTANT="value"
  local my_variable="value"
  
  # Functions: lowercase with underscores
  my_function() {
      local arg="$1"
      # ...
  }
  
  # Always quote variables
  echo "$my_variable"
  
  # Use [[ ]] for conditionals
  if [[ -f "$file" ]]; then
      # ...
  fi
  ```

### Python Code

- Follow [PEP 8](https://peps.python.org/pep-0008/)
- Include docstrings for all functions and classes
- Use type hints where practical
- Use `#!/usr/bin/env python3` shebang
- Maximum line length: 79 characters (code), 72 (docstrings)
- Example:
  ```python
  def my_function(param: str) -> bool:
      """Brief description.

      Args:
          param: Description of the parameter.

      Returns:
          Description of the return value.
      """
      return True
  ```

### PowerShell

- Use approved verbs (Get-, Set-, Install-, etc.)
- Include comment-based help (`<# .SYNOPSIS #>`)
- Follow [PowerShell Best Practices](https://docs.microsoft.com/en-us/powershell/scripting/developer/cmdlet/cmdlet-development-guidelines)

### Documentation (Markdown)

- Use proper heading hierarchy (`#`, `##`, `###`)
- Include code blocks with language specification
- Keep lines under 80 characters where possible
- Use clear, beginner-friendly language

---

## Commit Messages

Follow [Conventional Commits](https://www.conventionalcommits.org/):

| Type | Description |
|------|-------------|
| `feat:` | New feature |
| `fix:` | Bug fix |
| `docs:` | Documentation changes |
| `style:` | Formatting, no code change |
| `refactor:` | Code restructuring |
| `test:` | Adding or updating tests |
| `chore:` | Maintenance tasks |

Example:
```
feat: add Fedora-based installer script

- Detect Fedora, CentOS, RHEL distros
- Use dnf for package management
- Install same quantum packages as other installers
- Add Fedora docs to docs/fedora-based.md

Closes #42
```

---

## Testing Requirements

Before submitting a PR:

1. **Bash scripts** pass `shellcheck`:
   ```bash
   shellcheck scripts/*.sh setup.sh
   ```

2. **Python code** passes basic checks:
   ```bash
   python -m py_compile scripts/verify-setup.py
   python -m py_compile examples/*.py
   ```

3. **Test on at least one platform** from your changes target

4. **Run the verification script** after any package changes:
   ```bash
   python scripts/verify-setup.py
   ```

---

## Development Setup

```bash
# Clone your fork
git clone https://github.com/YOUR_USERNAME/quantum-dev-env.git
cd quantum-dev-env

# Create a branch
git checkout -b feature/my-feature

# Make scripts executable
chmod +x setup.sh scripts/*.sh

# Install shellcheck for linting
# Arch
sudo pacman -S shellcheck
# Ubuntu/Debian
sudo apt install shellcheck

# Test locally
./setup.sh --yes
```

---

## Adding a New Platform

To add support for a new Linux distribution:

1. **Create** `scripts/install-<distro>.sh` following existing patterns
2. **Update** `scripts/detect-os.sh` to detect the new distro
3. **Update** `setup.sh` to route to the new installer
4. **Create** `docs/<distro>-based.md` with manual installation guide
5. **Update** `README.md` supported platforms table
6. **Test** on the target distribution

---

## Areas We Need Help

- 🍎 **macOS support** — installer script and documentation
- 🐧 **Fedora/RHEL support** — dnf-based installer
- 🧪 **More examples** — quantum algorithms, VQE, QAOA
- 🌐 **Translations** — README and docs in other languages
- 📦 **Additional frameworks** — Amazon Braket, Azure Quantum
- 🔄 **CI/CD improvements** — test on more platforms

---

## License

By contributing, you agree that your contributions will be licensed under the [MIT License](../LICENSE).

---

Thank you for making quantum computing more accessible! ⚛️
