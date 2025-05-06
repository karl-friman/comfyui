FROM nvidia/cuda:12.1.1-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install Python, pip, and essentials
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.10 python3-pip python3-venv \
    git \
    ca-certificates \
    curl \
    wget \
    procps \
    bzip2 \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Create a virtual environment
ENV VENV_DIR=/opt/venv
RUN python3 -m venv $VENV_DIR
ENV PATH="$VENV_DIR/bin:$PATH"

# Clone ComfyUI (latest)
WORKDIR /opt
RUN git clone https://github.com/comfyanonymous/ComfyUI.git

WORKDIR /opt/ComfyUI

# Install PyTorch for CUDA 12.1 and other dependencies
RUN pip install --upgrade pip && \
    pip install torch==2.2.0 torchvision==0.17.0 torchaudio==2.2.0 --index-url https://download.pytorch.org/whl/cu121 && \
    pip install -r requirements.txt

# Install Jupyter Notebook and jupyter_server_proxy
RUN pip install notebook==7.1.3 jupyter_server_proxy==4.1.2

# Environment variables for Jupyter configuration
ENV JUPYTER_PASSWORD=""
ENV NOTEBOOK_DIR="/workspace"
ENV JUPYTER_PORT="8888"
ENV COMFYUI_PORT="8188"

EXPOSE ${JUPYTER_PORT} ${COMFYUI_PORT}

RUN mkdir -p ${NOTEBOOK_DIR}
WORKDIR ${NOTEBOOK_DIR}

COPY start.sh /usr/local/bin/start.sh
RUN chmod +x /usr/local/bin/start.sh

CMD ["/usr/local/bin/start.sh"]
