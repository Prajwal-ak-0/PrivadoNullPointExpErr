# Privado CLI Cgroup v2 Compatibility Solution

This repository contains a solution for running Privado CLI in environments using cgroup v2, which is becoming the default in many modern Linux distributions.

## Problem

Privado CLI uses Java 18, which has issues with container detection in cgroup v2 environments, leading to a `NullPointerException` related to `jdk.internal.platform.CgroupInfo.getMountPoint()`.

## Solution

Our solution creates a custom Docker image that:

- Creates a wrapper script for the Java binary
- Sets environment variables to disable container support
- Uses JVM flags to disable container detection

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

3. The script will build a custom Docker image that solves the previously mentioned issue.

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

2. The patched image is built using Docker

**Note**: The script does NOT install privado-cli for you. Please install the modified privado-cli from [here](https://github.com/SuchitG04/privado-cli). After installation, `cd` into the directory and run `go build -o privado`. The binary will be created in the same directory.


## Technical Details

- Java Version: OpenJDK 18.0.2 (used by Privado)
- Cgroup Version: v2
- Container Runtime: Docker

## Troubleshooting

If you encounter issues:

1. Make sure Docker is running with cgroup v2 support
2. Ensure Docker has sufficient permissions to access your directories
3. If you get permission errors when installing, try running the installation script with sudo
