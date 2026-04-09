#!/usr/bin/env python3
"""
02-bell-state.py - Quantum Entanglement with Bell States 🔗

This example creates a Bell state — the simplest example of
quantum entanglement. Two qubits become correlated in a way
that has no classical equivalent.

Concepts covered:
  - Quantum entanglement
  - Bell states (|Φ+⟩)
  - Hadamard gate (H)
  - CNOT gate (CX)
  - Multi-qubit systems
  - Measurement correlations

What to expect:
  The two qubits will always be measured in the SAME state:
  both |00⟩ or both |11⟩, each with ~50% probability.
  You will NEVER see |01⟩ or |10⟩. This perfect correlation
  is quantum entanglement.

Usage:
  python 02-bell-state.py
"""

from qiskit import QuantumCircuit
from qiskit_aer import AerSimulator

try:
    import matplotlib.pyplot as plt
    from qiskit.visualization import plot_histogram

    HAS_MATPLOTLIB = True
except ImportError:
    HAS_MATPLOTLIB = False


def main():
    """Create and simulate a Bell state circuit."""

    print("=" * 60)
    print("  🔗 Quantum Entanglement: Bell State")
    print("=" * 60)
    print()

    # ──────────────────────────────────────────────────────────
    # What is a Bell State?
    # ──────────────────────────────────────────────────────────
    # A Bell state is a quantum state of two qubits that are
    # maximally entangled. The state we'll create is |Φ+⟩:
    #
    #   |Φ+⟩ = (|00⟩ + |11⟩) / √2
    #
    # This means: if you measure one qubit and get 0, the
    # other qubit will ALWAYS be 0 too (and vice versa).
    # This correlation is instantaneous, regardless of distance!

    # ──────────────────────────────────────────────────────────
    # Step 1: Create a 2-qubit circuit
    # ──────────────────────────────────────────────────────────
    print("📝 Step 1: Creating a 2-qubit quantum circuit")
    qc = QuantumCircuit(2, 2)
    # Both qubits start in state |0⟩
    # Combined initial state: |00⟩

    # ──────────────────────────────────────────────────────────
    # Step 2: Apply Hadamard gate to qubit 0
    # ──────────────────────────────────────────────────────────
    # H|0⟩ = (|0⟩ + |1⟩) / √2
    #
    # After this step, the state is:
    #   (|0⟩ + |1⟩) / √2  ⊗  |0⟩  =  (|00⟩ + |10⟩) / √2
    #
    # Qubit 0 is in superposition, qubit 1 is still |0⟩.
    # They are NOT yet entangled.
    print("🔀 Step 2: Hadamard gate on qubit 0 (superposition)")
    qc.h(0)

    # ──────────────────────────────────────────────────────────
    # Step 3: Apply CNOT gate (Control=0, Target=1)
    # ──────────────────────────────────────────────────────────
    # The CNOT (Controlled-NOT, or CX) gate flips the target
    # qubit IF the control qubit is |1⟩:
    #   |00⟩ → |00⟩  (control is 0, target unchanged)
    #   |10⟩ → |11⟩  (control is 1, target flipped)
    #
    # After this step, the state becomes:
    #   (|00⟩ + |11⟩) / √2  =  Bell state |Φ+⟩
    #
    # NOW the qubits are ENTANGLED! Neither qubit has a
    # definite state on its own — only the pair has a state.
    print("🔗 Step 3: CNOT gate (creating entanglement)")
    qc.cx(0, 1)

    # ──────────────────────────────────────────────────────────
    # Step 4: Measure both qubits
    # ──────────────────────────────────────────────────────────
    print("📏 Step 4: Measuring both qubits")
    qc.measure([0, 1], [0, 1])

    # ──────────────────────────────────────────────────────────
    # Visualize the circuit
    # ──────────────────────────────────────────────────────────
    print("\n🔧 Circuit diagram:")
    print(qc.draw(output="text"))
    print()

    # ──────────────────────────────────────────────────────────
    # Step 5: Simulate
    # ──────────────────────────────────────────────────────────
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
    print("💡 Key Observations:")
    print("   • You only see |00⟩ and |11⟩ — never |01⟩ or |10⟩")
    print("   • The qubits are always measured in the SAME state")
    print("   • This perfect correlation is ENTANGLEMENT")
    print("   • Einstein called this 'spooky action at a distance'")
    print()

    # ──────────────────────────────────────────────────────────
    # Step 7: Visualization (optional)
    # ──────────────────────────────────────────────────────────
    if HAS_MATPLOTLIB:
        print("📈 Generating histogram plot...")
        fig = plot_histogram(counts, title="Bell State |Φ+⟩ Measurement Results")
        fig.savefig("bell_state_results.png", dpi=150, bbox_inches="tight")
        print("   Saved to: bell_state_results.png")
        plt.show()
    else:
        print("ℹ️  Install matplotlib to see a histogram visualization:")
        print("   pip install matplotlib")

    print()
    print("🎓 What you learned:")
    print("   1. The Hadamard gate creates superposition")
    print("   2. The CNOT gate creates entanglement")
    print("   3. Entangled qubits are perfectly correlated")
    print("   4. This is the foundation of quantum computing!")
    print()


if __name__ == "__main__":
    main()
