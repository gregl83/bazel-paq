FROM ubuntu:24.04

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install required dependencies
RUN apt-get update && apt-get install -y \
    apt-transport-https \
    curl \
    gnupg \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Add Bazel distribution URI as a package source
RUN curl -fsSL https://bazel.build/bazel-release.pub.gpg | gpg --dearmor -o /usr/share/keyrings/bazel-archive-keyring.gpg

RUN echo "deb [arch=amd64 signed-by=/usr/share/keyrings/bazel-archive-keyring.gpg] https://storage.googleapis.com/bazel-apt stable jdk1.8" | tee /etc/apt/sources.list.d/bazel.list

# Install Bazel
RUN apt-get update && apt-get install -y bazel \
    && rm -rf /var/lib/apt/lists/*

# Verify installation
RUN bazel --version

# Set working directory
WORKDIR /workspace

CMD ["/bin/bash"]