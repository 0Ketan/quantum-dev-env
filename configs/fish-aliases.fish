# ==============================================================================
# Quantum Dev Environment - Fish Shell Aliases
# ==============================================================================
# This file is automatically copied to ~/.config/fish/conf.d/ by the installer.
# Fish shell uses a different alias/function syntax than bash/zsh.
# ==============================================================================

# Activate the quantum computing virtual environment
alias qenv='source ~/quantum/.venv/bin/activate.fish'

# Navigate to the quantum project directory
alias qcd='cd ~/quantum'

# Run the environment verification script
alias qtest='python ~/quantum/verify-setup.py'

# Start Jupyter Notebook in the quantum directory
function qjupyter
    cd ~/quantum
    source .venv/bin/activate.fish
    jupyter notebook
end

# Start Jupyter Lab in the quantum directory
function qlab
    cd ~/quantum
    source .venv/bin/activate.fish
    jupyter lab
end

# Quick-run a quantum example
function qexample
    cd ~/quantum
    source .venv/bin/activate.fish
    python examples/01-hello-quantum.py
end
