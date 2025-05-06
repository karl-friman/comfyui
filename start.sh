#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status

# --- Environment Setup ---
# Activate Conda environment if not already (good practice in scripts)
# The Dockerfile's CMD runs in a shell where PATH should already be set,
# but explicit activation can be more robust in some contexts.
# Source this carefully as it might not work in all non-interactive shells
# if [ -f "/opt/conda/etc/profile.d/conda.sh" ]; then
#     source "/opt/conda/etc/profile.d/conda.sh"
#     conda activate comfy # CONDA_ENV_NAME from Dockerfile
# else
#     echo "Warning: Conda profile script not found."
# fi
# For Docker CMD, relying on PATH set in Dockerfile is usually sufficient.
PYTHON_EXEC="/opt/conda/envs/comfy/bin/python3" # Python from our 'comfy' env
JUPYTER_EXEC="/opt/conda/envs/comfy/bin/jupyter"
COMFYUI_DIR="/opt/ComfyUI"

# --- Jupyter Notebook Configuration ---
JUPYTER_EFFECTIVE_PORT="${JUPYTER_PORT:-8888}"
NOTEBOOK_DIR_TO_USE="${NOTEBOOK_DIR:-/workspace}"

JUPYTER_CMD_ARGS="--ip=0.0.0.0 --port=${JUPYTER_EFFECTIVE_PORT} --no-browser --allow-root --notebook-dir=${NOTEBOOK_DIR_TO_USE}"

if [ -n "$JUPYTER_PASSWORD" ]; then
    echo "Jupyter password is set. Hashing password..."
    if ! $PYTHON_EXEC -c "import sys; sys.exit(0) if sys.version_info >= (3,0) else sys.exit(1)"; then
        echo "Error: Python 3 at $PYTHON_EXEC not found or not working." >&2
        exit 1
    fi
    if ! $PYTHON_EXEC -c "import notebook.auth" &> /dev/null; then
        echo "Error: 'notebook.auth' module not found by Python at $PYTHON_EXEC." >&2
        exit 1
    fi

    HASHED_PASSWORD=$($PYTHON_EXEC -c "from notebook.auth import passwd; print(passwd('$JUPYTER_PASSWORD', 'sha256'))")
    JUPYTER_CMD_ARGS="$JUPYTER_CMD_ARGS --NotebookApp.password='$HASHED_PASSWORD'"
    echo "Jupyter Notebook configured with a password. Access on port ${JUPYTER_EFFECTIVE_PORT}."
else
    JUPYTER_CMD_ARGS="$JUPYTER_CMD_ARGS --NotebookApp.token=''" # Disable token authentication
    echo "Jupyter Notebook configured without token/password. Access on port ${JUPYTER_EFFECTIVE_PORT}."
fi

# Start Jupyter Notebook in the background
echo "Starting Jupyter Notebook..."
mkdir -p "${NOTEBOOK_DIR_TO_USE}" # Ensure notebook directory exists
${JUPYTER_EXEC} notebook ${JUPYTER_CMD_ARGS} &
JUPYTER_PID=$!
echo "Jupyter Notebook PID: $JUPYTER_PID. Logs might appear interleaved."
sleep 5 # Give Jupyter a moment to start

# --- ComfyUI Configuration & Launch ---
COMFYUI_EFFECTIVE_PORT="${COMFYUI_PORT:-8188}"

echo "Preparing to start ComfyUI..."

# Default arguments for ComfyUI. Add others if needed.
# The --listen argument makes it accessible from outside the container.
COMFYUI_ARGS="--listen --port ${COMFYUI_EFFECTIVE_PORT}"

# If you want to pass extra arguments to ComfyUI via an environment variable at runtime:
if [ -n "$COMFYUI_EXTRA_ARGS" ]; then
    COMFYUI_ARGS="$COMFYUI_ARGS $COMFYUI_EXTRA_ARGS"
fi

echo "Starting ComfyUI from ${COMFYUI_DIR} with args: ${COMFYUI_ARGS}"
cd "${COMFYUI_DIR}"
exec $PYTHON_EXEC main.py ${COMFYUI_ARGS}
