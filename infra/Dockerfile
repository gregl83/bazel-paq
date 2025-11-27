FROM ubuntu:24.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install required dependencies as root
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    curl \
    gnupg \
    ca-certificates \
    unzip \
    build-essential \
    gcc \
    g++ \
    python3 \
    python3-pip \
    tree \
    && rm -rf /var/lib/apt/lists/*

# Set environment variables
ENV HOME=/home/ubuntu
ENV USER=ubuntu

# Create workspace and ensure ubuntu user owns their home
RUN mkdir -p /workspace && chown -R ubuntu:ubuntu /workspace /home/ubuntu

# Switch to non-root user
USER ubuntu
WORKDIR /home/ubuntu

# Install Bazelisk (manages Bazel versions automatically)
RUN curl -fsSL https://github.com/bazelbuild/bazelisk/releases/latest/download/bazelisk-linux-amd64 -o bazelisk \
    && chmod +x bazelisk \
    && mkdir -p /home/ubuntu/bin \
    && mv bazelisk /home/ubuntu/bin/bazel

# Add to PATH
ENV PATH="/home/ubuntu/bin:${PATH}"

# Verify installation
RUN bazel --version

# Set working directory
WORKDIR /workspace

CMD ["/bin/bash"]
