FROM zhangp365/comfyui:latest

# Install Jupyter Notebook, pip, procps (for ps command), and other utilities
# Using apt-get from the base image which is Ubuntu-based.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        procps \
        python3-pip \
    && pip install --no-cache-dir \
        notebook \
        jupyter_server_proxy \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Keep everything else commented out for now
# ENV JUPYTER_PASSWORD=""
# ENV NOTEBOOK_DIR="/workspace"
# ENV JUPYTER_PORT="8888"
# EXPOSE ${JUPYTER_PORT}
# COPY start.sh /usr/local/bin/start.sh
# RUN chmod +x /usr/local/bin/start.sh
# CMD ["/usr/local/bin/start.sh"]
