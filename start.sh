#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status

# --- Environment Setup ---
# PYTHON_EXEC and JUPYTER_EXEC point to the executables within our created Conda environment
PYTHON_EXEC="/opt/conda/envs/comfy/bin/python3"
JUPYTER_EXEC="/opt/conda/envs/comfy/bin/jupyter"
COMFYUI_DIR="/opt/ComfyUI" # Location where ComfyUI was cloned in the Dockerfile

# --- Jupyter Notebook Configuration ---
JUPYTER_EFFECTIVE_PORT="${JUPYTER_PORT:-8888}" # Use JUPYTER_PORT from env, default 8888
NOTEBOOK_DIR_TO_USE="${NOTEBOOK_DIR:-/workspace}" # Use NOTEBOOK_DIR from env, default /workspace

JUPYTER_CMD_ARGS="--ip=0.0.0.0 --port=${JUPYTER_EFFECTIVE_PORT} --no-browser --allow-root --notebook-dir=${NOTEBOOK_DIR_TO_USE}"

if [ -n "$JUPYTER_PASSWORD" ]; then
    echo "Jupyter password is set. Hashing password..."
    # Ensure Python and notebook.auth are available
    if ! $PYTHON_EXEC -c "import sys; sys.exit(0) if sys.version_info >= (3,0) else sys.exit(1)"; then
        echo "Error: Python 3 at $PYTHON_EXEC not found or not working." >&2
        exit 1
    fi
    # The Dockerfile now includes a verification step for notebook.auth,
    # but an extra check here doesn't hurt.
    if ! $PYTHON_EXEC -c "import notebook.auth" &> /dev/null; then
        echo "Error: 'notebook.auth' module not found by Python at $PYTHON_EXEC." >&2
        echo "This indicates an issue with the 'notebook' package installation in the Docker image." >&2
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
COMFYUI_EFFECTIVE_PORT="${COMFYUI_PORT:-8188}" # Use COMFYUI_PORT from env, default 8188

echo "Preparing to start ComfyUI..."

# Default arguments for ComfyUI.
# The --listen argument makes it accessible from outside the container.
COMFYUI_ARGS="--listen --port ${COMFYUI_EFFECTIVE_PORT}"

# If you want to pass extra arguments to ComfyUI via an environment variable at runtime:
if [ -n "$COMFYUI_EXTRA_ARGS" ]; then
    echo "Adding extra ComfyUI args: $COMFYUI_EXTRA_ARGS"
    COMFYUI_ARGS="$COMFYUI_ARGS $COMFYUI_EXTRA_ARGS"
fi

echo "Starting ComfyUI from ${COMFYUI_DIR} with args: ${COMFYUI_ARGS}"
cd "${COMFYUI_DIR}" # Change to ComfyUI directory before running main.py
exec $PYTHON_EXEC main.py ${COMFYUI_ARGS}
