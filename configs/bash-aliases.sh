# ==============================================================================
# Quantum Dev Environment - Bash Aliases
# ==============================================================================
# These aliases are automatically added to ~/.bashrc by the installer.
# You can also source this file manually: source /path/to/bash-aliases.sh
# ==============================================================================

# Activate the quantum computing virtual environment
alias qenv='source ~/quantum/.venv/bin/activate'

# Navigate to the quantum project directory
alias qcd='cd ~/quantum'

# Run the environment verification script
alias qtest='python ~/quantum/verify-setup.py'

# Start Jupyter Notebook in the quantum directory
alias qjupyter='cd ~/quantum && source .venv/bin/activate && jupyter notebook'

# Start Jupyter Lab in the quantum directory
alias qlab='cd ~/quantum && source .venv/bin/activate && jupyter lab'

# Quick-run a quantum example
alias qexample='cd ~/quantum && source .venv/bin/activate && python examples/01-hello-quantum.py'
