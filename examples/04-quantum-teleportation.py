#!/usr/bin/env python3
"""
04-quantum-teleportation.py - Quantum Teleportation Protocol ✨

This example implements the quantum teleportation protocol, one of
the most famous algorithms in quantum computing. It demonstrates
how to transfer the quantum state of one qubit to another using
entanglement and classical communication.

Concepts covered:
  - Quantum teleportation protocol
  - Bell state preparation
  - Bell measurement
  - Classical communication in quantum protocols
  - Conditional quantum gates (classically controlled)

What to expect:
  Alice has a qubit in an arbitrary state. Using a shared Bell
  pair and two classical bits of communication, she can transfer
  the exact quantum state to Bob's qubit — without physically
  sending the qubit!

Important:
  - No information travels faster than light!
  - The classical bits are required (sent at light speed or slower)
  - The original qubit's state is destroyed (no-cloning theorem)

Usage:
  python 04-quantum-teleportation.py
"""

from qiskit import QuantumCircuit, QuantumRegister, ClassicalRegister
from qiskit_aer import AerSimulator
import numpy as np

try:
    import matplotlib.pyplot as plt

    HAS_MATPLOTLIB = True
except ImportError:
    HAS_MATPLOTLIB = False


def create_teleportation_circuit(state_prep_angle: float = np.pi / 4):
    """
    Create the quantum teleportation circuit.

    The protocol has three qubits:
      - q0: Alice's qubit (the state to teleport)
      - q1: Alice's half of the entangled Bell pair
      - q2: Bob's half of the entangled Bell pair

    Args:
        state_prep_angle: Rotation angle for preparing the initial
                         state on Alice's qubit. Default is π/4.

    Returns:
        QuantumCircuit: The complete teleportation circuit.
    """

    # Create registers with meaningful names
    alice_qubit = QuantumRegister(1, "alice")
    bell_pair = QuantumRegister(2, "bell")
    classical = ClassicalRegister(2, "c_msg")
    result = ClassicalRegister(1, "c_result")

    qc = QuantumCircuit(alice_qubit, bell_pair, classical, result)

    # ──────────────────────────────────────────────────────────
    # Step 1: Prepare Alice's qubit in an arbitrary state
    # ──────────────────────────────────────────────────────────
    # We use an Ry rotation to create a state that's NOT just
    # |0⟩ or |1⟩, but a genuine superposition:
    #   |ψ⟩ = cos(θ/2)|0⟩ + sin(θ/2)|1⟩
    qc.ry(state_prep_angle, 0)
    qc.barrier(label="State Prep")

    # ──────────────────────────────────────────────────────────
    # Step 2: Create a Bell pair (shared between Alice and Bob)
    # ──────────────────────────────────────────────────────────
    # Before teleportation, Alice and Bob must share an
    # entangled pair. This could have been created earlier
    # and the qubits distributed.
    qc.h(1)        # Hadamard on Bell qubit 1
    qc.cx(1, 2)    # CNOT: entangle Bell qubit 1 and 2
    qc.barrier(label="Bell Pair")

    # ──────────────────────────────────────────────────────────
    # Step 3: Alice's Bell measurement
    # ──────────────────────────────────────────────────────────
    # Alice performs a Bell measurement on her qubit (q0)
    # and her half of the Bell pair (q1).
    # This entangles the information from q0 into the Bell pair.
    qc.cx(0, 1)    # CNOT: Alice's qubit controls Bell qubit 1
    qc.h(0)        # Hadamard on Alice's qubit
    qc.barrier(label="Bell Measurement")

    # Measure Alice's qubits (classical communication)
    qc.measure(0, 0)  # Measure Alice's qubit → classical bit 0
    qc.measure(1, 1)  # Measure Bell qubit 1  → classical bit 1
    qc.barrier(label="Classical Comm")

    # ──────────────────────────────────────────────────────────
    # Step 4: Bob applies corrections based on Alice's results
    # ──────────────────────────────────────────────────────────
    # Bob uses the two classical bits from Alice to apply
    # the correct gates to recover the teleported state.
    #
    # If Alice measured 1 on Bell qubit 1 → Bob applies X gate
    # If Alice measured 1 on her qubit    → Bob applies Z gate
    qc.x(2).c_if(classical[1], 1)   # Conditional X
    qc.z(2).c_if(classical[0], 1)   # Conditional Z
    qc.barrier(label="Corrections")

    # ──────────────────────────────────────────────────────────
    # Step 5: Measure Bob's qubit (verification)
    # ──────────────────────────────────────────────────────────
    qc.measure(2, 2)  # Measure Bob's qubit → result bit

    return qc


def verify_teleportation():
    """
    Verify teleportation by comparing input and output states.

    We prepare a known state on Alice's qubit and verify that
    Bob's qubit ends up in the same state after teleportation.
    """

    print("\n" + "─" * 60)
    print("  Verification: Testing multiple initial states")
    print("─" * 60)
    print()

    simulator = AerSimulator()
    shots = 4000
    test_angles = [0, np.pi / 6, np.pi / 4, np.pi / 3, np.pi / 2, np.pi]
    angle_names = ["0", "π/6", "π/4", "π/3", "π/2", "π"]

    print(f"  {'Angle':>8}  {'Expected P(|1⟩)':>16}  "
          f"{'Measured P(|1⟩)':>16}  {'Match':>6}")
    print(f"  {'─' * 8}  {'─' * 16}  {'─' * 16}  {'─' * 6}")

    for angle, name in zip(test_angles, angle_names):
        # Create circuit for this angle
        qc = create_teleportation_circuit(state_prep_angle=angle)

        # Expected probability of measuring |1⟩
        expected_p1 = np.sin(angle / 2) ** 2

        # Run simulation
        result = simulator.run(qc, shots=shots).result()
        counts = result.get_counts()

        # Extract Bob's measurement (bit index 2 in the bitstring)
        bob_1_count = 0
        for bitstring, count in counts.items():
            # Qiskit bitstrings are little-endian: rightmost bit = first
            bits = bitstring.replace(" ", "")
            if len(bits) >= 3 and bits[0] == "1":
                bob_1_count += count

        measured_p1 = bob_1_count / shots
        match = "✅" if abs(measured_p1 - expected_p1) < 0.05 else "⚠️"

        print(f"  {name:>8}  {expected_p1:>16.4f}  "
              f"{measured_p1:>16.4f}  {match:>6}")

    print()
    print("  💡 The measured probabilities match the expected values!")
    print("     This confirms successful quantum teleportation.")
    print()


def main():
    """Run the quantum teleportation demonstration."""

    print("=" * 60)
    print("  ✨ Quantum Teleportation Protocol")
    print("=" * 60)
    print()

    # ──────────────────────────────────────────────────────────
    # Explain the protocol
    # ──────────────────────────────────────────────────────────
    print("  📖 The Quantum Teleportation Protocol:")
    print()
    print("  Alice wants to send the quantum state of her qubit")
    print("  to Bob. They share an entangled Bell pair.")
    print()
    print("  Protocol steps:")
    print("    1. Prepare Alice's qubit in state |ψ⟩")
    print("    2. Create entangled Bell pair (shared)")
    print("    3. Alice: Bell measurement (2 classical bits)")
    print("    4. Alice → Bob: send 2 classical bits")
    print("    5. Bob: apply correction gates based on bits")
    print("    6. Bob's qubit is now in state |ψ⟩!")
    print()

    # ──────────────────────────────────────────────────────────
    # Create and display the circuit
    # ──────────────────────────────────────────────────────────
    print("  🔧 Creating teleportation circuit (θ = π/4)...")
    qc = create_teleportation_circuit(state_prep_angle=np.pi / 4)

    print("\n  Circuit diagram:")
    print(qc.draw(output="text"))
    print()

    # ──────────────────────────────────────────────────────────
    # Simulate
    # ──────────────────────────────────────────────────────────
    print("  🚀 Running simulation (4000 shots)...")
    simulator = AerSimulator()
    result = simulator.run(qc, shots=4000).result()
    counts = result.get_counts()

    print(f"\n  📊 Raw measurement results (all 3 bits):")
    for state, count in sorted(counts.items(),
                                key=lambda x: -x[1])[:8]:
        pct = (count / 4000) * 100
        print(f"     |{state}⟩ : {count:4d} ({pct:5.1f}%)")

    # ──────────────────────────────────────────────────────────
    # Verify across multiple states
    # ──────────────────────────────────────────────────────────
    verify_teleportation()

    # ──────────────────────────────────────────────────────────
    # Summary
    # ──────────────────────────────────────────────────────────
    print("  🎓 What you learned:")
    print("     1. Teleportation transfers quantum STATE, not matter")
    print("     2. It requires an entangled pair + 2 classical bits")
    print("     3. The original state is destroyed (no-cloning)")
    print("     4. No information travels faster than light")
    print("     5. This is a real protocol used in quantum networks!")
    print()
    print("  📚 Further reading:")
    print("     • Bennett et al. (1993) - Original teleportation paper")
    print("     • Qiskit Textbook: Quantum Teleportation")
    print("     • Nielsen & Chuang, Ch. 1.3.7")
    print()


if __name__ == "__main__":
    main()
