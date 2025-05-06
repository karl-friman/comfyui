FROM zhangp365/comfyui:latest

# Install utilities using apt-get
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        procps \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Jupyter Notebook and jupyter_server_proxy using Conda
# The base image should have conda in /opt/conda/bin/conda
# We also ensure pip is up-to-date within conda for any pip installs it might do.
RUN echo "Attempting to install notebook and jupyter_server_proxy using Conda..." && \
    /opt/conda/bin/conda install -y -c conda-forge \
        notebook \
        jupyter_server_proxy \
    && echo "Conda install finished. Upgrading pip within conda..." && \
    /opt/conda/bin/python -m pip install --no-cache-dir --upgrade pip \
    && echo "Pip upgrade finished. Cleaning conda..." && \
    /opt/conda/bin/conda clean -tipsy \
    && echo "Conda clean finished. Verifying notebook.auth directly..." \
    && /opt/conda/bin/python3 -c "import notebook.auth; print('>>> notebook.auth successfully imported after conda install in Dockerfile <<<')" \
    && echo "Notebook package verification successful."

# Environment variables for Jupyter configuration
ENV JUPYTER_PASSWORD=""
# Jupyter's working directory for notebooks
ENV NOTEBOOK_DIR="/workspace"
ENV JUPYTER_PORT="8888"

# Expose Jupyter's port. ComfyUI's 8188 is already exposed by the base image.
EXPOSE ${JUPYTER_PORT}

# Copy the startup script and make it executable
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Override the CMD from the base image to use our script.
CMD ["/usr/local/bin/start.sh"]
