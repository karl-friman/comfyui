FROM zhangp365/comfyui:latest

# Install Jupyter Notebook and other useful tools like procps (for ps command)
# Using apt-get from the base image which is Ubuntu-based.
RUN apt-get update && apt-get install -y --no-install-recommends \
    procps \
    python3-pip \
    && pip install --no-cache-dir \
    notebook \
    jupyter_server_proxy \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Environment variables for Jupyter configuration
ENV JUPYTER_PASSWORD=""
ENV NOTEBOOK_DIR="/workspace" # Jupyter's working directory for notebooks
ENV JUPYTER_PORT="8888"

# Expose Jupyter's port. ComfyUI's 8188 is already exposed by the base image.
EXPOSE ${JUPYTER_PORT}

# The base image's WORKDIR is /app. ComfyUI will run from there.
# Jupyter will use NOTEBOOK_DIR.

# Copy the startup script and make it executable
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Override the CMD from the base image to use our script.
# The base image's ENTRYPOINT (/scripts/docker-entrypoint.sh) will run first,
# and then it will execute this new CMD.
CMD ["/usr/local/bin/start.sh"]
