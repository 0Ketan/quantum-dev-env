# 📚 Example Quantum Programs

A collection of beginner-friendly quantum computing examples using [Qiskit](https://qiskit.org/). Each example builds on the previous one, gradually introducing more complex quantum concepts.

## Prerequisites

Make sure your quantum environment is activated:

```bash
qenv  # Activate the virtual environment
```

## Examples

### 01 — Hello Quantum 👋

**File:** `01-hello-quantum.py`

Your very first quantum program! Creates a single qubit, puts it in superposition with a Hadamard gate, and measures it.

**Concepts:** Qubits, Hadamard gate, measurement, superposition

```bash
python examples/01-hello-quantum.py
```

**Expected Output:**
- A circuit diagram showing `H` gate and measurement
- Roughly 50/50 distribution between |0⟩ and |1⟩

---

### 02 — Bell State (Entanglement) 🔗

**File:** `02-bell-state.py`

Creates a Bell state — the simplest example of quantum entanglement. Two qubits become perfectly correlated.

**Concepts:** Entanglement, Bell states, CNOT gate, multi-qubit systems

```bash
python examples/02-bell-state.py
```

**Expected Output:**
- Only |00⟩ and |11⟩ states appear (never |01⟩ or |10⟩)
- Each with ~50% probability
- Optional: histogram saved as `bell_state_results.png`

---

### 03 — Superposition Explorer 🌊

**File:** `03-superposition.py`

Deep dive into quantum superposition. Shows how measurement statistics converge as you increase the number of shots, and demonstrates multi-qubit superposition.

**Concepts:** Statistical convergence, probability distributions, quantum parallelism

```bash
python examples/03-superposition.py
```

**Expected Output:**
- Convergence table showing P(|0⟩) approaching 0.5
- 3-qubit superposition with all 8 states equally likely
- Optional: probability distribution plot

---

### 04 — Quantum Teleportation ✨

**File:** `04-quantum-teleportation.py`

The crown jewel! Implements the full quantum teleportation protocol — transferring a quantum state from Alice to Bob using entanglement and classical communication.

**Concepts:** Teleportation protocol, Bell measurement, classical communication, conditional gates

```bash
python examples/04-quantum-teleportation.py
```

**Expected Output:**
- Full teleportation circuit diagram
- Raw measurement statistics
- Verification table comparing expected vs. measured probabilities

---

## Running All Examples

```bash
# Run all examples in sequence
for example in examples/0*.py; do
    echo "Running $example..."
    python "$example"
    echo ""
done
```

## Creating Your Own

Want to write your own quantum programs? Start with this template:

```python
#!/usr/bin/env python3
"""My Quantum Experiment."""

from qiskit import QuantumCircuit
from qiskit_aer import AerSimulator

# Create circuit
qc = QuantumCircuit(2, 2)

# Add gates
qc.h(0)         # Hadamard
qc.cx(0, 1)     # CNOT
qc.measure_all() # Measure

# Simulate
sim = AerSimulator()
result = sim.run(qc, shots=1000).result()
print(result.get_counts())
```

## Further Learning

| Resource | Link |
|----------|------|
| Qiskit Textbook | [qiskit.org/learn](https://qiskit.org/learn) |
| IBM Quantum | [quantum.ibm.com](https://quantum.ibm.com) |
| Cirq Documentation | [quantumai.google/cirq](https://quantumai.google/cirq) |
| PennyLane Demos | [pennylane.ai/qml](https://pennylane.ai/qml) |
| Quantum Country | [quantum.country](https://quantum.country) |
| MinutePhysics QC | [YouTube series](https://www.youtube.com/watch?v=F_Riqjdh2oM) |
