#!/bin/bash
set -e # Exit immediately if a command exits with a non-zero status

# --- Jupyter Notebook Configuration ---
JUPYTER_PORT="${JUPYTER_PORT:-8888}" # Allow override via env var
NOTEBOOK_DIR_TO_USE="${NOTEBOOK_DIR:-/workspace}" # Default to /workspace for Jupyter files

JUPYTER_CMD_ARGS="--ip=0.0.0.0 --port=${JUPYTER_PORT} --no-browser --allow-root --notebook-dir=${NOTEBOOK_DIR_TO_USE}"

if [ -n "$JUPYTER_PASSWORD" ]; then
    # Ensure python3 and notebook package are available
    HASHED_PASSWORD=$(python3 -c "from notebook.auth import passwd; print(passwd('$JUPYTER_PASSWORD', 'sha256'))")
    JUPYTER_CMD_ARGS="$JUPYTER_CMD_ARGS --NotebookApp.password='$HASHED_PASSWORD'"
    echo "Jupyter Notebook configured with a password. Access on port ${JUPYTER_PORT}."
else
    JUPYTER_CMD_ARGS="$JUPYTER_CMD_ARGS --NotebookApp.token=''" # Disable token authentication
    echo "Jupyter Notebook configured without token/password. Access on port ${JUPYTER_PORT}."
fi

# Start Jupyter Notebook in the background
echo "Starting Jupyter Notebook..."
# Ensure the notebook directory exists
mkdir -p "${NOTEBOOK_DIR_TO_USE}"
jupyter notebook ${JUPYTER_CMD_ARGS} &
JUPYTER_PID=$!
echo "Jupyter Notebook PID: $JUPYTER_PID. Logs might appear interleaved."
sleep 5 # Give Jupyter a moment to start and print its initial logs

# --- ComfyUI Configuration & Launch ---
# The base image's ENTRYPOINT (/scripts/docker-entrypoint.sh) has already run.
# The original CMD (as per your layer dump) was effectively "python3 /app/main.py $CLI_ARGS"
# The WORKDIR is /app (set by the base image).

echo "Preparing to start ComfyUI..."
echo "Current CLI_ARGS: '$CLI_ARGS'"

# We need to ensure ComfyUI listens on the correct port and is accessible.
# The base image exposes 8188.
# If CLI_ARGS is empty or doesn't specify listening behavior, we add defaults.
# If CLI_ARGS is set, we assume it contains necessary arguments, but we'll append ours if port/listen are missing.

COMFYUI_EXEC_CMD="python3 /app/main.py"
COMFYUI_FINAL_ARGS=""

# Check if CLI_ARGS already contains --listen or --port
has_listen=0
has_port=0
if [[ "$CLI_ARGS" == *"--listen"* ]]; then
    has_listen=1
fi
if [[ "$CLI_ARGS" == *"--port"* ]]; then
    has_port=1
fi

if [ -n "$CLI_ARGS" ]; then
    COMFYUI_FINAL_ARGS="$CLI_ARGS"
fi

if [ "$has_listen" -eq 0 ]; then
    COMFYUI_FINAL_ARGS="$COMFYUI_FINAL_ARGS --listen"
fi

if [ "$has_port" -eq 0 ]; then
    # Default ComfyUI port
    COMFYUI_FINAL_ARGS="$COMFYUI_FINAL_ARGS --port 8188"
fi

# Trim leading/trailing whitespace from COMFYUI_FINAL_ARGS
COMFYUI_FINAL_ARGS=$(echo "$COMFYUI_FINAL_ARGS" | awk '{$1=$1};1')


echo "Starting ComfyUI with command: $COMFYUI_EXEC_CMD $COMFYUI_FINAL_ARGS"
# `exec` replaces the shell process with the ComfyUI process.
# This makes ComfyUI the main foreground process.
exec $COMFYUI_EXEC_CMD $COMFYUI_FINAL_ARGS

# If ComfyUI exits, the script (and thus container) will stop.
# Fallback to keep container alive if exec fails (should not happen with set -e)
# wait $JUPYTER_PID
