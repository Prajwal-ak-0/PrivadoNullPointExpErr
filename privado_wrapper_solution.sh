#!/bin/bash

# This script provides a cgroup v2 compatible wrapper for running Privado CLI
# It creates a custom Docker image with Java container detection disabled

# Create a Dockerfile for the patched Privado image
cat > Dockerfile.patched << 'EOF'
FROM public.ecr.aws/privado/privado:latest

# Install necessary tools
RUN apt-get update && apt-get install -y \
    curl \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Create a wrapper script for Java that disables container detection
RUN echo '#!/bin/bash' > /usr/local/java/jdk-18.0.2/bin/java.wrapper && \
    echo 'exec /usr/local/java/jdk-18.0.2/bin/java.real \
    -XX:-UseContainerSupport \
    -Djdk.internal.platform.useContainerSupport=false \
    "$@"' >> /usr/local/java/jdk-18.0.2/bin/java.wrapper && \
    chmod +x /usr/local/java/jdk-18.0.2/bin/java.wrapper

# Rename the original Java binary and replace it with our wrapper
RUN mv /usr/local/java/jdk-18.0.2/bin/java /usr/local/java/jdk-18.0.2/bin/java.real && \
    mv /usr/local/java/jdk-18.0.2/bin/java.wrapper /usr/local/java/jdk-18.0.2/bin/java

# Set environment variables to disable container support
ENV JAVA_TOOL_OPTIONS="-XX:-UseContainerSupport -Djdk.internal.platform.useContainerSupport=false"
ENV _JAVA_OPTIONS="-XX:-UseContainerSupport -Djdk.internal.platform.useContainerSupport=false"
EOF

# Build the patched image
echo "Building patched Privado image..."
sudo docker build -t privado-patched:latest -f Dockerfile.patched .

echo " Privado CLI with cgroup v2 compatibility has been installed!"
echo "You can now run 'privado scan <directory>' to scan your code."
