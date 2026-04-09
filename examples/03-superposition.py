#!/usr/bin/env python3
"""
03-superposition.py - Exploring Quantum Superposition 🌊

This example demonstrates quantum superposition in detail by
placing a single qubit into superposition and statistically
analyzing the measurement outcomes across many runs.

Concepts covered:
  - Superposition as a fundamental quantum property
  - Probability distributions
  - Repeated measurement and statistics
  - Comparison with classical randomness
  - Multi-qubit superposition (all qubits in H)

What to expect:
  A qubit in superposition yields |0⟩ and |1⟩ with roughly
  equal probability. We'll verify this statistically and
  visualize the distribution.

Usage:
  python 03-superposition.py
"""

from qiskit import QuantumCircuit
from qiskit_aer import AerSimulator
import numpy as np

try:
    import matplotlib.pyplot as plt

    HAS_MATPLOTLIB = True
except ImportError:
    HAS_MATPLOTLIB = False


def single_qubit_superposition():
    """Demonstrate superposition with a single qubit."""

    print("\n" + "─" * 60)
    print("  Part 1: Single Qubit Superposition")
    print("─" * 60)
    print()
    print("  A qubit in state |0⟩ has 100% chance of measuring 0.")
    print("  After a Hadamard gate, it's in superposition:")
    print("  |ψ⟩ = (|0⟩ + |1⟩) / √2")
    print("  Now it has 50% chance of each outcome.")
    print()

    # Create circuit: H gate + measurement
    qc = QuantumCircuit(1, 1)
    qc.h(0)
    qc.measure(0, 0)

    print("  Circuit:")
    print(f"  {qc.draw(output='text')}")
    print()

    # Run with increasing numbers of shots to show convergence
    simulator = AerSimulator()
    shot_counts = [10, 100, 1000, 10000]

    print("  📊 How probabilities converge with more measurements:")
    print(f"  {'Shots':>8}  {'P(|0⟩)':>8}  {'P(|1⟩)':>8}  {'Deviation':>10}")
    print(f"  {'─' * 8}  {'─' * 8}  {'─' * 8}  {'─' * 10}")

    for shots in shot_counts:
        result = simulator.run(qc, shots=shots).result()
        counts = result.get_counts()
        p0 = counts.get("0", 0) / shots
        p1 = counts.get("1", 0) / shots
        deviation = abs(p0 - 0.5)
        print(f"  {shots:>8}  {p0:>8.4f}  {p1:>8.4f}  {deviation:>10.4f}")

    print()
    print("  💡 Notice: as shots increase, probabilities converge to 50%")
    print("     This is a fundamental property of quantum measurement!")
    print()


def multi_qubit_superposition():
    """Demonstrate superposition with multiple qubits."""

    print("\n" + "─" * 60)
    print("  Part 2: Multi-Qubit Superposition")
    print("─" * 60)
    print()
    print("  With N qubits, all in superposition, we get 2^N possible")
    print("  states, each with equal probability. This is the basis")
    print("  of quantum parallelism!")
    print()

    num_qubits = 3
    shots = 4000

    # Create circuit: H gate on all qubits
    qc = QuantumCircuit(num_qubits, num_qubits)
    for i in range(num_qubits):
        qc.h(i)
    qc.measure(range(num_qubits), range(num_qubits))

    print(f"  Circuit ({num_qubits} qubits, all in superposition):")
    print(f"  {qc.draw(output='text')}")
    print()

    # Simulate
    simulator = AerSimulator()
    result = simulator.run(qc, shots=shots).result()
    counts = result.get_counts()

    # Display results
    num_states = 2 ** num_qubits
    expected_prob = 1.0 / num_states

    print(f"  Expected: {num_states} states, each with "
          f"P = 1/{num_states} = {expected_prob:.4f}")
    print()
    print(f"  {'State':>8}  {'Count':>6}  {'P(measured)':>12}  "
          f"{'P(expected)':>12}  {'Visual'}")
    print(f"  {'─' * 8}  {'─' * 6}  {'─' * 12}  {'─' * 12}  {'─' * 20}")

    for state in sorted(
        [format(i, f"0{num_qubits}b") for i in range(num_states)]
    ):
        count = counts.get(state, 0)
        prob = count / shots
        bar = "█" * int(prob * 80)
        print(f"  |{state}⟩  {count:>6}  {prob:>12.4f}  "
              f"{expected_prob:>12.4f}  {bar}")

    print()
    print(f"  💡 All {num_states} states appear with roughly equal "
          f"probability!")
    print(f"     {num_qubits} qubits explore {num_states} states "
          f"simultaneously.")
    print(f"     With 300 qubits, that's more states than atoms "
          f"in the universe!")
    print()

    return counts


def visualize_distribution(counts: dict):
    """Create a probability distribution visualization."""

    if not HAS_MATPLOTLIB:
        print("  ℹ️  Install matplotlib to see the visualization:")
        print("     pip install matplotlib")
        return

    print("  📈 Generating probability distribution plot...")

    # Sort by state
    states = sorted(counts.keys())
    probabilities = [counts[s] / sum(counts.values()) for s in states]
    expected = 1.0 / len(states)

    fig, ax = plt.subplots(figsize=(10, 5))

    # Bar chart
    x = np.arange(len(states))
    bars = ax.bar(x, probabilities, color="#6366f1", alpha=0.8, width=0.6)

    # Expected line
    ax.axhline(
        y=expected, color="#ef4444", linestyle="--",
        linewidth=2, label=f"Expected: {expected:.4f}"
    )

    # Labels
    ax.set_xlabel("Quantum State", fontsize=12)
    ax.set_ylabel("Probability", fontsize=12)
    ax.set_title(
        "Superposition: Equal Probability Distribution", fontsize=14
    )
    ax.set_xticks(x)
    ax.set_xticklabels([f"|{s}⟩" for s in states], fontsize=10)
    ax.legend(fontsize=11)
    ax.set_ylim(0, max(probabilities) * 1.3)

    plt.tight_layout()
    plt.savefig("superposition_results.png", dpi=150, bbox_inches="tight")
    print("  Saved to: superposition_results.png")
    plt.show()


def main():
    """Run the superposition demonstration."""

    print("=" * 60)
    print("  🌊 Quantum Superposition Explorer")
    print("=" * 60)

    # Part 1: Single qubit convergence
    single_qubit_superposition()

    # Part 2: Multi-qubit equal distribution
    counts = multi_qubit_superposition()

    # Part 3: Visualization
    visualize_distribution(counts)

    print("🎓 What you learned:")
    print("   1. Superposition gives equal probability of all states")
    print("   2. More measurements → probabilities converge to theory")
    print("   3. N qubits in superposition = 2^N simultaneous states")
    print("   4. This parallelism is why quantum computers are powerful")
    print()


if __name__ == "__main__":
    main()
