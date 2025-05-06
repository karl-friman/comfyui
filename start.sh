#!/bin/bash
set -e

PYTHON_EXEC="/opt/venv/bin/python"
JUPYTER_EXEC="/opt/venv/bin/jupyter"
COMFYUI_DIR="/opt/ComfyUI"

JUPYTER_EFFECTIVE_PORT="${JUPYTER_PORT:-8888}"
NOTEBOOK_DIR_TO_USE="${NOTEBOOK_DIR:-/workspace}"

JUPYTER_CMD_ARGS="--ip=0.0.0.0 --port=${JUPYTER_EFFECTIVE_PORT} --no-browser --allow-root --notebook-dir=${NOTEBOOK_DIR_TO_USE}"

if [ -n "$JUPYTER_PASSWORD" ]; then
    HASHED_PASSWORD=$($PYTHON_EXEC -c "from notebook.auth import passwd; print(passwd('$JUPYTER_PASSWORD', 'sha256'))")
    JUPYTER_CMD_ARGS="$JUPYTER_CMD_ARGS --NotebookApp.password='$HASHED_PASSWORD'"
    echo "Jupyter Notebook configured with a password."
else
    JUPYTER_CMD_ARGS="$JUPYTER_CMD_ARGS --NotebookApp.token=''"
    echo "Jupyter Notebook configured without token/password."
fi

echo "Starting Jupyter Notebook..."
mkdir -p "${NOTEBOOK_DIR_TO_USE}"
${JUPYTER_EXEC} notebook ${JUPYTER_CMD_ARGS} &
JUPYTER_PID=$!
sleep 5

COMFYUI_EFFECTIVE_PORT="${COMFYUI_PORT:-8188}"
COMFYUI_ARGS="--listen --port ${COMFYUI_EFFECTIVE_PORT}"

if [ -n "$COMFYUI_EXTRA_ARGS" ]; then
    COMFYUI_ARGS="$COMFYUI_ARGS $COMFYUI_EXTRA_ARGS"
fi

echo "Starting ComfyUI..."
cd "${COMFYUI_DIR}"
exec $PYTHON_EXEC main.py ${COMFYUI_ARGS}
