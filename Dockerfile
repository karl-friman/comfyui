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
ENV CONDA_DIR=/opt/conda
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O ~/miniconda.sh && \
    /bin/bash ~/miniconda.sh -b -p $CONDA_DIR && \
    rm ~/miniconda.sh
ENV PATH=$CONDA_DIR/bin:$PATH

# Create a Conda environment
ENV CONDA_ENV_NAME=comfy
RUN conda create -y -n $CONDA_ENV_NAME python=3.10 && \
    conda clean -a -y

# Activate Conda environment for subsequent RUN commands IN THIS STAGE
SHELL ["conda", "run", "-n", "comfy", "/bin/bash", "-c"]

# Stage 2: Install ComfyUI and Jupyter
FROM base AS builder

ENV CONDA_ENV_NAME=comfy

# Activate Conda environment for subsequent RUN commands IN THIS STAGE
SHELL ["conda", "run", "-n", "comfy", "/bin/bash", "-c"]

# Clone ComfyUI repository (pin to a specific commit for reproducibility)
WORKDIR /opt
RUN git clone https://github.com/comfyanonymous/ComfyUI.git && \
    cd ComfyUI && \
    git checkout 7e2e2e1 # <-- Replace with a specific commit hash or tag

WORKDIR /opt/ComfyUI

# Install ComfyUI dependencies (PyTorch for CUDA 12.1, pin versions as needed)
RUN pip install torch==2.2.0 torchvision==0.17.0 torchaudio==2.2.0 --index-url https://download.pytorch.org/whl/cu121 && \
    pip install -r requirements.txt

# Install Jupyter Notebook and jupyter_server_proxy (pin versions as needed)
RUN pip install --no-cache-dir notebook==7.1.3 jupyter_server_proxy==4.1.2

# Verify notebook.auth can be imported
RUN python -c "import notebook.auth; print('>>> notebook.auth successfully imported in new environment <<<')"

# Stage 3: Final image
# Start from 'base' which has conda but not the activated env by default
FROM base AS final

ENV CONDA_ENV_NAME=comfy
ENV PATH=/opt/conda/envs/$CONDA_ENV_NAME/bin:/opt/conda/bin:$PATH

# Copy the entire conda directory for robustness
COPY --from=builder /opt/conda /opt/conda
COPY --from=builder /opt/ComfyUI /opt/ComfyUI

# Environment variables for Jupyter configuration (can be overridden at runtime)
ENV JUPYTER_PASSWORD=""
ENV NOTEBOOK_DIR="/workspace"
ENV JUPYTER_PORT="8888"
ENV COMFYUI_PORT="8188"

# Expose ports
EXPOSE ${JUPYTER_PORT} ${COMFYUI_PORT}

# Create a default workspace and set it as WORKDIR for Jupyter
RUN mkdir -p ${NOTEBOOK_DIR}
WORKDIR ${NOTEBOOK_DIR}

# Copy the startup script
COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

# Set the startup script as the command
CMD ["/usr/local/bin/start.sh"]
