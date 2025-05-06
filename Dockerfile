FROM zhangp365/comfyui:latest

# Install utilities using apt-get
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        procps \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install Jupyter Notebook using Conda
# Then, if jupyter_server_proxy is still desired and not pulled in by notebook, try pip for it.
RUN echo "Attempting to install notebook using Conda..." && \
    /opt/conda/bin/conda install -y -c conda-forge \
        notebook \
    && echo "Conda install of notebook finished. Upgrading pip within conda..." && \
    /opt/conda/bin/python -m pip install --no-cache-dir --upgrade pip \
    && echo "Pip upgrade finished. Attempting to install jupyter-server-proxy using pip..." && \
    /opt/conda/bin/python -m pip install --no-cache-dir jupyter-server-proxy \
    && echo "Installation of jupyter-server-proxy via pip finished. Cleaning conda..." && \
    /opt/conda/bin/conda clean -tipsy \
    && echo "Conda clean finished. Verifying notebook.auth directly..." \
    && /opt/conda/bin/python3 -c "import notebook.auth; print('>>> notebook.auth successfully imported after conda/pip install in Dockerfile <<<')" \
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
