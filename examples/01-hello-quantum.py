#!/usr/bin/env python3
"""
01-hello-quantum.py - Your First Quantum Circuit! 🎉

This example creates the simplest possible quantum circuit:
a single qubit put into superposition using a Hadamard gate,
then measured.

Concepts covered:
  - Quantum bits (qubits) vs classical bits
  - The Hadamard gate (H)
  - Quantum measurement
  - Superposition

What to expect:
  When you measure a qubit in superposition, you get either
  |0⟩ or |1⟩ with roughly equal probability (~50% each).
  This is fundamentally different from a classical coin flip
  because the qubit exists in BOTH states simultaneously
  until measured.

Usage:
  python 01-hello-quantum.py
"""

from qiskit import QuantumCircuit
from qiskit_aer import AerSimulator


def main():
    """Create and run a simple quantum circuit."""

    print("=" * 60)
    print("  ⚛️  Hello, Quantum World!")
    print("=" * 60)
    print()

    # ──────────────────────────────────────────────────────────
    # Step 1: Create a quantum circuit
    # ──────────────────────────────────────────────────────────
    # QuantumCircuit(1, 1) creates a circuit with:
    #   - 1 quantum bit (qubit)  → starts in state |0⟩
    #   - 1 classical bit        → stores the measurement result
    print("📝 Step 1: Creating a quantum circuit with 1 qubit")
    qc = QuantumCircuit(1, 1)

    # ──────────────────────────────────────────────────────────
    # Step 2: Apply a Hadamard gate
    # ──────────────────────────────────────────────────────────
    # The Hadamard gate (H) puts the qubit into superposition:
    #   |0⟩  →  (|0⟩ + |1⟩) / √2
    #
    # This means the qubit is now in BOTH |0⟩ and |1⟩ states
    # simultaneously! This is quantum superposition.
    print("🔀 Step 2: Applying Hadamard gate (creating superposition)")
    qc.h(0)  # Apply H gate to qubit 0

    # ──────────────────────────────────────────────────────────
    # Step 3: Measure the qubit
    # ──────────────────────────────────────────────────────────
    # Measurement collapses the superposition into a definite
    # state: either |0⟩ or |1⟩ with equal probability.
    # The result is stored in the classical bit.
    print("📏 Step 3: Measuring the qubit")
    qc.measure(0, 0)  # Measure qubit 0, store in classical bit 0

    # ──────────────────────────────────────────────────────────
    # Step 4: Visualize the circuit
    # ──────────────────────────────────────────────────────────
    print("\n🔧 Circuit diagram:")
    print(qc.draw(output="text"))
    print()

    # ──────────────────────────────────────────────────────────
    # Step 5: Simulate the circuit
    # ──────────────────────────────────────────────────────────
    # We run the circuit 1000 times to see the probability
    # distribution. Since the qubit is in superposition, we
    # expect roughly 500 times |0⟩ and 500 times |1⟩.
    print("🚀 Step 5: Running simulation (1000 shots)...")
    simulator = AerSimulator()
    result = simulator.run(qc, shots=1000).result()
    counts = result.get_counts()

    # ──────────────────────────────────────────────────────────
    # Step 6: Display results
    # ──────────────────────────────────────────────────────────
    print("\n📊 Results:")
    print(f"   Measurement outcomes: {counts}")
    print()

    total = sum(counts.values())
    for state, count in sorted(counts.items()):
        percentage = (count / total) * 100
        bar = "█" * int(percentage / 2)
        print(f"   |{state}⟩ : {count:4d} ({percentage:5.1f}%) {bar}")

    print()
    print("💡 Explanation:")
    print("   The qubit was in superposition (both |0⟩ and |1⟩)")
    print("   Each measurement randomly collapsed to one state")
    print("   With ~50/50 probability — that's quantum mechanics!")
    print()
    print("🎉 Congratulations! You just ran your first quantum circuit!")
    print()


if __name__ == "__main__":
    main()
