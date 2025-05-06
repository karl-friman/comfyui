FROM zhangp365/comfyui:latest

# Test 1: Just a simple RUN command
RUN echo "Test"

# Test 2: Copy the script (if Test 1 passes)
# COPY start.sh /usr/local/bin/start.sh
# RUN chmod +x /usr/local/bin/start.sh

# Test 3: Set the CMD (if Test 2 passes)
# CMD ["/usr/local/bin/start.sh"]
