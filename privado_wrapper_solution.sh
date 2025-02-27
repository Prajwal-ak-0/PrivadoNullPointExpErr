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

# Create a dummy internal config directory
RUN mkdir -p /privado-core/config

# Create a simple entrypoint script
RUN echo '#!/bin/bash' > /entrypoint.sh && \
    echo 'echo "Running Privado with cgroup v2 compatibility fix..."' >> /entrypoint.sh && \
    echo 'if [ "$1" = "scan" ]; then' >> /entrypoint.sh && \
    echo '  # Get the target directory from arguments' >> /entrypoint.sh && \
    echo '  TARGET_DIR="${@: -1}"' >> /entrypoint.sh && \
    echo '  if [ "$TARGET_DIR" = "." ]; then' >> /entrypoint.sh && \
    echo '    TARGET_DIR="/app"' >> /entrypoint.sh && \
    echo '  elif [[ "$TARGET_DIR" != /* ]]; then' >> /entrypoint.sh && \
    echo '    # If relative path, prepend /app/' >> /entrypoint.sh && \
    echo '    TARGET_DIR="/app/$TARGET_DIR"' >> /entrypoint.sh && \
    echo '  fi' >> /entrypoint.sh && \
    echo '  # Create .privado directory in the app directory' >> /entrypoint.sh && \
    echo '  mkdir -p "$TARGET_DIR/.privado"' >> /entrypoint.sh && \
    echo '  # Run privado-core with the correct parameters' >> /entrypoint.sh && \
    echo '  exec /privado-core/bin/privado-core scan --internal-config /privado-core/config "$TARGET_DIR"' >> /entrypoint.sh && \
    echo 'else' >> /entrypoint.sh && \
    echo '  exec /privado-core/bin/privado-core "$@"' >> /entrypoint.sh && \
    echo 'fi' >> /entrypoint.sh && \
    chmod +x /entrypoint.sh

# Set the entrypoint
ENTRYPOINT ["/entrypoint.sh"]
EOF

# Build the patched image
echo "Building patched Privado image..."
docker build -t privado-patched -f Dockerfile.patched .

# Create a wrapper script for the privado command
cat > privado << 'EOF'
#!/bin/bash

# Check if at least one argument is provided
if [ $# -lt 1 ]; then
  echo "Usage: privado [scan|validate|upload|metadata] [options] <args>..."
  exit 1
fi

# Get the current directory
CURRENT_DIR=$(pwd)

# Run the patched Privado image with the provided arguments
docker run --rm -it \
  -v "$CURRENT_DIR:/app" \
  --security-opt seccomp=unconfined \
  --cgroupns=host \
  privado-patched \
  "$@"

# Check if the scan completed successfully
if [ $? -eq 0 ] && [ "$1" = "scan" ]; then
  echo ""
  echo " Privado scan completed successfully!"
  echo "Results are available in the .privado directory"
fi
EOF

# Make the wrapper script executable
chmod +x privado

# Move the wrapper script to a location in PATH
sudo mv privado /usr/local/bin/

echo " Privado CLI with cgroup v2 compatibility has been installed!"
echo "You can now run 'privado scan <directory>' to scan your code."
