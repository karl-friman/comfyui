# Stage 1: Base with CUDA, Conda, and common tools
FROM nvidia/cuda:12.1.1-devel-ubuntu22.04 AS base

ENV DEBIAN_FRONTEND=noninteractive

# Install Miniconda, git, procps, and other essentials
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    wget \
    git \
    procps \
    bzip2 \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install Miniconda
ENV CONDA_DIR /opt/conda
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p $CONDA_DIR && \
    rm ~/miniconda.sh
ENV PATH=$CONDA_DIR/bin:$PATH

# Create a Conda environment
ENV CONDA_ENV_NAME=comfy
RUN conda create -y -n $CONDA_ENV_NAME python=3.10 && \
    conda clean -a -y # CORRECTED ARGUMENTS FOR CONDA CLEAN

# Activate Conda environment for subsequent RUN commands
SHELL ["conda", "run", "-n", "$CONDA_ENV_NAME", "/bin/bash", "-c"]

# Stage 2: Install ComfyUI and Jupyter
FROM base AS builder

# Activate Conda environment
SHELL ["conda", "run", "-n", "$CONDA_ENV_NAME", "/bin/bash", "-c"]

# Clone ComfyUI repository
WORKDIR /opt
RUN git clone https://github.com/comfyanonymous/ComfyUI.git
WORKDIR /opt/ComfyUI

# Install ComfyUI dependencies (PyTorch for CUDA 12.1)
# Refer to ComfyUI manual installation for specific PyTorch versions if needed
RUN pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
RUN pip install -r requirements.txt

# Install Jupyter Notebook and any other Python tools needed by your start script
RUN pip install --no-cache-dir notebook jupyter_server_proxy

# Verify notebook.auth can be imported
RUN python -c "import notebook.auth; print('>>> notebook.auth successfully imported in new environment <<<')"

# Stage 3: Final image
FROM base AS final

ENV CONDA_ENV_NAME=comfy
ENV PATH=/opt/conda/envs/$CONDA_ENV_NAME/bin:/opt/conda/bin:$PATH

# Copy ComfyUI from builder stage
COPY --from=builder /opt/ComfyUI /opt/ComfyUI
# Copy the Conda environment from builder stage (contains ComfyUI deps and Jupyter)
COPY --from=builder /opt/conda/envs/$CONDA_ENV_NAME /opt/conda/envs/$CONDA_ENV_NAME

# Environment variables for Jupyter configuration (can be overridden at runtime)
ENV JUPYTER_PASSWORD=""
# Jupyter's working directory for notebooks
ENV NOTEBOOK_DIR="/workspace"
ENV JUPYTER_PORT="8888"
ENV COMFYUI_PORT="8188"

# Expose ports
EXPOSE ${JUPYTER_PORT} ${COMFYUI_PORT}

# Create a default workspace and set it as WORKDIR for Jupyter
RUN mkdir -p ${NOTEBOOK_DIR}
WORKDIR ${NOTEBOOK_DIR} # Default for Jupyter

# Copy the startup script
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Set the startup script as the command
# The ENTRYPOINT is not set here, so `start.sh` is the direct command.
CMD ["/usr/local/bin/start.sh"]
