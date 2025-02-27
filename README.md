# Privado CLI Cgroup v2 Compatibility Solution

This repository contains a solution for running Privado CLI in environments using cgroup v2, which is becoming the default in many modern Linux distributions.

## Problem

Privado CLI uses Java 18, which has issues with container detection in cgroup v2 environments, leading to a `NullPointerException` related to `jdk.internal.platform.CgroupInfo.getMountPoint()`.

## Solution

Our solution creates a custom Docker image that:

1. Disables Java container detection using multiple methods:
   - Creates a wrapper script for the Java binary
   - Sets environment variables to disable container support
   - Uses JVM flags to disable container detection

2. Creates a custom entrypoint script that automatically adds the required `--internal-config` parameter when running the scan command.

3. Installs a wrapper script that allows you to use Privado CLI with the same command-line interface as the original.

## Files

- `privado_wrapper_solution.sh`: Installation script that builds the patched Docker image and installs the Privado wrapper
- `README.md`: Documentation for the solution

## Installation

1. Make sure Docker is installed and running
2. Run the installation script:

```bash
chmod +x privado_wrapper_solution.sh
./privado_wrapper_solution.sh
```

3. The script will install a `privado` command in `/usr/local/bin/` that you can use just like the regular Privado CLI.

## Usage

After installation, you can use the Privado CLI as normal:

```bash
# Scan the current directory
privado scan .

# Scan a specific directory
privado scan BankingSystem-Backend

# Get help
privado --help
```

## How It Works

1. The installation script creates a custom Dockerfile that:
   - Uses the official Privado Docker image as a base
   - Creates a wrapper for the Java binary that disables container detection
   - Sets environment variables to disable container support
   - Creates a custom entrypoint script that handles the command-line arguments

2. The patched image is built using Docker

3. A wrapper script is installed in `/usr/local/bin/` that runs the patched Docker image with the necessary volume mounts and security options

4. When you run the `privado` command, it automatically mounts the current directory into the container and passes your arguments to the Privado CLI

## Customization

You can customize the solution to fit your specific needs by modifying the Dockerfile or the entrypoint script.

### Modifying the Dockerfile

1. **Add Additional Tools**: You can install additional tools by adding them to the `apt-get install` command in the Dockerfile.

2. **Change Base Image**: If you need a different base image, modify the `FROM` line to use another Docker image.

3. **Modify Java Wrapper**: Adjust the Java wrapper script to include additional JVM flags or environment variables as needed.

### Modifying the Entrypoint Script

1. **Add Custom Commands**: You can add custom commands or logic to the entrypoint script to perform additional setup or configuration.

2. **Change Argument Handling**: Modify how command-line arguments are processed to add new options or change existing behavior.

3. **Customize Output**: Adjust the output messages or logging to suit your needs.

After making changes, rebuild the Docker image using the installation script to apply your customizations.

## Technical Details

- Java Version: OpenJDK 18.0.2 (used by Privado)
- Cgroup Version: v2
- Container Runtime: Docker

## Troubleshooting

If you encounter issues:

1. Make sure Docker is running with cgroup v2 support
2. Ensure Docker has sufficient permissions to access your directories
3. If you get permission errors when installing, try running the installation script with sudo
