# Deployment

## PCIe-Client

The deployment process automates the installation and configuration of the PCIe client on NVIDIA Jetson devices. This directory contains the necessary Ansible playbooks and scripts to deploy the PCIe client to multiple Jetson devices simultaneously.

### Prerequisites

- Ansible installed on your deployment machine
- SSH access to target Jetson devices
- Environment variables configured (see below)

### Directory Structure

```
deployment/
├── deploy-pcie-client.yml  # Main Ansible playbook for PCIe client deployment
├── deploy-pcie-client.sh   # Shell script wrapper for deployment
├── inventory.yml           # Target device inventory configuration
└── README.md               # This documentation file
```

### Configuration

1. **Environment Variables**

   All credentials and configuration settings are stored in the repository's root `.env` file. A template is provided in `.env.template` at the repository root.
   
   Required environment variables:
   ```
   ANSIBLE_USER=username     # SSH username for Jetson devices
   ANSIBLE_PASSWORD=password # SSH password for Jetson devices
   ```

2. **Inventory Configuration**

   The `inventory.yml` file defines the target Jetson devices. Update the IP addresses to match your environment:
   ```yaml
   jetson1:
     ansible_host: 192.168.1.101  # Replace with actual IP address
   jetson2:
     ansible_host: 192.168.1.102  # Replace with actual IP address
   ```

### Deployment Instructions

1. **Update Environment Variables**

   Ensure your `.env` file at the repository root contains valid credentials:
   ```
   ANSIBLE_USER=your_actual_username
   ANSIBLE_PASSWORD=your_actual_password
   ```

2. **Make Deployment Script Executable**

   Before running the deployment script for the first time, you need to make it executable:
   ```bash
   chmod +x deploy-pcie-client.sh
   ```

3. **Run Deployment Script**

   ```bash
   cd deployment
   ./deploy-pcie-client.sh
   ```
   
   This script loads environment variables from the root `.env` file and executes the Ansible playbook.

4. **Manual Deployment (Alternative)**

   If you prefer to run the playbook directly:
   ```bash
   cd deployment
   ansible-playbook -i inventory.yml deploy-pcie-client.yml --extra-vars "ansible_user=username ansible_password=password"
   ```

### What Gets Deployed

The deployment process:

1. Installs required dependencies on the target Jetson devices
2. Copies PCIe client source code to each device
3. Compiles the PCIe client
4. Installs the compiled binary to `/usr/local/bin/`
5. Sets up a systemd service to automatically run the PCIe client on startup
6. Starts the service

### Troubleshooting

- **SSH Connection Issues**: Verify SSH credentials and ensure the Jetson devices are reachable
- **Build Failures**: Check for required dependencies on the target devices
- **Service Failures**: Examine logs with `journalctl -u pcie-client`

### Advanced Configuration

For additional customization options, modify the `deploy-pcie-client.yml` playbook. Key parameters that can be adjusted include:

- `target_dir`: The directory where the PCIe client is deployed on the target devices
- Build options in the generated Makefile
- Service configuration parameters

