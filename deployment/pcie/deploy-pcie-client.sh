#!/bin/bash

# Path to repository root directory
REPO_ROOT="$(dirname "$(dirname "$(readlink -f "$0")")")"

# Load environment variables from .env file in root directory
if [ -f "$REPO_ROOT/.env" ]; then
    export $(grep -v '^#' "$REPO_ROOT/.env" | xargs)
    echo "Environment variables loaded from $REPO_ROOT/.env file"
else
    echo "No .env file found in $REPO_ROOT"
    exit 1
fi

# Check if required environment variables are set
if [ -z "$ANSIBLE_USER" ] || [ -z "$ANSIBLE_PASSWORD" ]; then
    echo "Error: ANSIBLE_USER and ANSIBLE_PASSWORD must be set in the .env file"
    exit 1
fi

echo "Starting PCIe client deployment to Jetson devices..."

# Run ansible-playbook with inventory and credentials
ansible-playbook -i inventory.yml deploy-pcie-client.yml \
    --extra-vars "ansible_user=$ANSIBLE_USER ansible_password=$ANSIBLE_PASSWORD"

STATUS=$?
if [ $STATUS -eq 0 ]; then
    echo "Deployment completed successfully!"
else
    echo "Deployment failed with status code $STATUS"
    exit $STATUS
fi