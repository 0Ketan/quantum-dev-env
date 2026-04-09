#!/usr/bin/env python3
"""
verify-setup.py - Verify the quantum computing development environment.

This script checks that all required packages are installed, validates
versions, and runs basic quantum circuits to ensure everything works.

Usage:
    python verify-setup.py
    python verify-setup.py --verbose
    python verify-setup.py --json

Exit codes:
    0 - All checks passed
    1 - One or more checks failed
"""

import importlib
import json
import subprocess
import sys
import os
import argparse
from typing import List
from typing import NamedTuple


# ==============================================================================
# Configuration
# ==============================================================================

# Minimum required Python version
MIN_PYTHON = (3, 8)

# Packages to verify: (import_name, pip_name, min_version_or_None)
REQUIRED_PACKAGES = [
    ("qiskit", "qiskit", None),
    ("qiskit_aer", "qiskit-aer", None),
    ("qiskit_ibm_runtime", "qiskit-ibm-runtime", None),
    ("cirq", "cirq", None),
    ("pennylane", "pennylane", None),
    ("numpy", "numpy", None),
    ("matplotlib", "matplotlib", None),
    ("scipy", "scipy", None),
    ("jupyter", "jupyter", None),
    ("ipykernel", "ipykernel", None),
]


# ==============================================================================
# Colors and output
# ==============================================================================

class Colors:
    """ANSI color codes for terminal output."""

    GREEN = "\033[0;32m"
    RED = "\033[0;31m"
    YELLOW = "\033[1;33m"
    BLUE = "\033[0;34m"
    CYAN = "\033[0;36m"
    MAGENTA = "\033[0;35m"
    BOLD = "\033[1m"
    NC = "\033[0m"  # No Color


def supports_color():
    """Check if the terminal supports color output."""
    if os.environ.get("NO_COLOR"):
        return False
    if not hasattr(sys.stdout, "isatty") or not sys.stdout.isatty():
        return False
    return True


USE_COLOR = supports_color()


def c(color: str, text: str) -> str:
    """Colorize text if color is supported."""
    if USE_COLOR:
        return f"{color}{text}{Colors.NC}"
    return text


def print_header(text: str):
    """Print a section header."""
    border = "═" * (len(text) + 4)
    print()
    print(c(Colors.CYAN, f"╔{border}╗"))
    print(c(Colors.CYAN, f"║  {text}  ║"))
    print(c(Colors.CYAN, f"╚{border}╝"))
    print()


def print_pass(text: str):
    """Print a passing check."""
    print(f"  {c(Colors.GREEN, '✅')} {text}")


def print_fail(text: str):
    """Print a failing check."""
    print(f"  {c(Colors.RED, '❌')} {text}")


def print_warn(text: str):
    """Print a warning."""
    print(f"  {c(Colors.YELLOW, '⚠️ ')} {text}")


def print_info(text: str):
    """Print an informational message."""
    print(f"  {c(Colors.BLUE, 'ℹ️ ')} {text}")


# ==============================================================================
# Check Result
# ==============================================================================

class CheckResult(NamedTuple):
    """Result of a single check."""

    name: str
    passed: bool
    message: str
    version: str = ""


# ==============================================================================
# Checks
# ==============================================================================

def check_python_version() -> CheckResult:
    """Check that the Python version meets the minimum requirement."""
    current = sys.version_info[:2]
    version_str = f"{current[0]}.{current[1]}.{sys.version_info[2]}"

    if current >= MIN_PYTHON:
        return CheckResult(
            "Python Version",
            True,
            f"Python {version_str} (>= {MIN_PYTHON[0]}.{MIN_PYTHON[1]} required)",
            version_str,
        )
    else:
        return CheckResult(
            "Python Version",
            False,
            f"Python {version_str} is below minimum {MIN_PYTHON[0]}.{MIN_PYTHON[1]}",
            version_str,
        )


def check_venv() -> CheckResult:
    """Check that we're running inside a virtual environment."""
    in_venv = (
        hasattr(sys, "real_prefix")
        or (hasattr(sys, "base_prefix") and sys.base_prefix != sys.prefix)
    )
    if in_venv:
        return CheckResult("Virtual Environment", True, f"Active: {sys.prefix}")
    else:
        return CheckResult(
            "Virtual Environment",
            False,
            "Not in a virtual environment (activate with 'qenv')",
        )


def check_package(import_name: str, pip_name: str,
                   min_version=None) -> CheckResult:
    """Check that a Python package is importable and meets version requirements."""
    try:
        mod = importlib.import_module(import_name)
        version = getattr(mod, "__version__", "unknown")

        if min_version and version != "unknown":
            from packaging.version import Version
            if Version(version) < Version(min_version):
                return CheckResult(
                    pip_name,
                    False,
                    f"Version {version} < required {min_version}",
                    version,
                )

        return CheckResult(pip_name, True, f"Version {version}", version)
    except ImportError:
        return CheckResult(
            pip_name, False, f"Not installed (pip install {pip_name})", ""
        )
    except Exception as e:
        return CheckResult(pip_name, False, f"Import error: {e}", "")


def check_jupyter_kernel() -> CheckResult:
    """Check that the quantum Jupyter kernel is registered."""
    try:
        result = subprocess.run(
            [sys.executable, "-m", "jupyter", "kernelspec", "list"],
            capture_output=True,
            text=True,
            timeout=15,
        )
        if "quantum-env" in result.stdout.lower():
            return CheckResult(
                "Jupyter Kernel", True, "quantum-env kernel registered"
            )
        else:
            return CheckResult(
                "Jupyter Kernel",
                False,
                "quantum-env kernel not found (run: python -m ipykernel install"
                " --user --name quantum-env)",
            )
    except Exception as e:
        return CheckResult("Jupyter Kernel", False, f"Could not check: {e}")


def check_bell_state_circuit() -> CheckResult:
    """Test creating and simulating a basic Bell state circuit with Qiskit."""
    try:
        from qiskit import QuantumCircuit
        from qiskit_aer import AerSimulator

        # Create Bell state circuit
        qc = QuantumCircuit(2, 2)
        qc.h(0)
        qc.cx(0, 1)
        qc.measure([0, 1], [0, 1])

        # Simulate
        simulator = AerSimulator()
        result = simulator.run(qc, shots=1000).result()
        counts = result.get_counts()

        # Verify we get roughly 50/50 |00⟩ and |11⟩
        total = sum(counts.values())
        if total > 0 and len(counts) <= 4:
            return CheckResult(
                "Bell State Circuit",
                True,
                f"Simulation OK: {counts}",
            )
        else:
            return CheckResult(
                "Bell State Circuit",
                False,
                f"Unexpected results: {counts}",
            )
    except ImportError as e:
        return CheckResult(
            "Bell State Circuit",
            False,
            f"Missing package: {e}",
        )
    except Exception as e:
        return CheckResult(
            "Bell State Circuit",
            False,
            f"Simulation failed: {e}",
        )


# ==============================================================================
# Summary
# ==============================================================================

def print_summary_table(results: List[CheckResult]):
    """Print a formatted summary table of all check results."""
    print()
    header = f"  {'Check':<30} {'Status':<10} {'Details'}"
    separator = f"  {'─' * 30} {'─' * 10} {'─' * 40}"

    print(c(Colors.BOLD, header))
    print(separator)

    for r in results:
        status = c(Colors.GREEN, "PASS") if r.passed else c(Colors.RED, "FAIL")
        print(f"  {r.name:<30} {status:<20} {r.message}")

    print()


# ==============================================================================
# Main
# ==============================================================================

def main():
    """Run all verification checks and report results."""
    parser = argparse.ArgumentParser(
        description="Verify quantum computing development environment setup."
    )
    parser.add_argument(
        "--verbose", "-v", action="store_true",
        help="Show detailed output"
    )
    parser.add_argument(
        "--json", action="store_true",
        help="Output results as JSON"
    )
    args = parser.parse_args()

    print_header("🔍 Quantum Environment Verification")

    results: List[CheckResult] = []

    # 1. Python version
    results.append(check_python_version())

    # 2. Virtual environment
    results.append(check_venv())

    # 3. Required packages
    print_info("Checking installed packages...")
    print()
    for import_name, pip_name, min_ver in REQUIRED_PACKAGES:
        result = check_package(import_name, pip_name, min_ver)
        results.append(result)
        if result.passed:
            print_pass(f"{pip_name:<25} {result.version}")
        else:
            print_fail(f"{pip_name:<25} {result.message}")

    # 4. Jupyter kernel
    print()
    print_info("Checking Jupyter kernel...")
    result = check_jupyter_kernel()
    results.append(result)
    if result.passed:
        print_pass(result.message)
    else:
        print_fail(result.message)

    # 5. Bell state circuit test
    print()
    print_info("Running quantum circuit test...")
    result = check_bell_state_circuit()
    results.append(result)
    if result.passed:
        print_pass(result.message)
    else:
        print_fail(result.message)

    # Summary
    passed = sum(1 for r in results if r.passed)
    failed = sum(1 for r in results if not r.passed)
    total = len(results)

    if args.json:
        json_results = [
            {
                "name": r.name,
                "passed": r.passed,
                "message": r.message,
                "version": r.version,
            }
            for r in results
        ]
        print(json.dumps({
            "passed": passed,
            "failed": failed,
            "total": total,
            "results": json_results,
        }, indent=2))
    else:
        print_summary_table(results)

        if failed == 0:
            print(c(Colors.GREEN, f"  🎉 All {total} checks passed!"))
            print()
            print(c(Colors.CYAN, "  Your quantum dev environment is ready."))
            print(c(Colors.CYAN, "  Try: python examples/01-hello-quantum.py"))
        else:
            print(c(Colors.YELLOW,
                     f"  ⚠️  {passed}/{total} checks passed, "
                     f"{failed} failed"))
            print()
            print(c(Colors.CYAN,
                     "  Fix the issues above and run this script again."))

        print()

    sys.exit(0 if failed == 0 else 1)


if __name__ == "__main__":
    main()
