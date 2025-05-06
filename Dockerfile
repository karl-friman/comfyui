FROM zhangp365/comfyui:latest

# Install Jupyter Notebook
RUN pip install --no-cache-dir notebook

# Expose port 8888 for Jupyter Notebook
EXPOSE 8888

# Set the working directory
WORKDIR /workspace

# Start Jupyter Notebook
CMD ["jupyter", "notebook", "--ip=0.0.0.0", "--port=8888", "--no-browser", "--allow-root"]
