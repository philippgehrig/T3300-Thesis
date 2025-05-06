#!/bin/bash

# check_jetpack_installation.sh
# Script to check if NVIDIA JetPack is installed on a Jetson device

# Set colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "====================================================="
echo "NVIDIA JetPack Installation Verification Tool"
echo "====================================================="

# Check for NVIDIA specific packages
echo -e "\n${YELLOW}Checking for NVIDIA JetPack packages...${NC}"
if dpkg -l | grep -q "nvidia-jetpack"; then
    echo -e "${GREEN}✓ nvidia-jetpack metapackage is installed${NC}"
    JETPACK_VERSION=$(dpkg -l | grep "nvidia-jetpack" | awk '{print $3}')
    echo -e "${GREEN}✓ JetPack version: ${JETPACK_VERSION}${NC}"
else
    echo -e "${RED}✗ nvidia-jetpack metapackage not found${NC}"
    echo -e "${YELLOW}Checking for individual components...${NC}"
fi

# Check for CUDA
if dpkg -l | grep -q "cuda-toolkit"; then
    CUDA_VERSION=$(dpkg -l | grep "cuda-toolkit" | awk '{print $3}')
    echo -e "${GREEN}✓ CUDA Toolkit installed: ${CUDA_VERSION}${NC}"
else
    echo -e "${RED}✗ CUDA Toolkit not found${NC}"
fi

# Check for cuDNN
if dpkg -l | grep -q "cudnn"; then
    CUDNN_VERSION=$(dpkg -l | grep "cudnn" | head -1 | awk '{print $3}')
    echo -e "${GREEN}✓ cuDNN installed: ${CUDNN_VERSION}${NC}"
else
    echo -e "${RED}✗ cuDNN not found${NC}"
fi

# Check for TensorRT
if dpkg -l | grep -q "tensorrt"; then
    TENSORRT_VERSION=$(dpkg -l | grep "tensorrt" | head -1 | awk '{print $3}')
    echo -e "${GREEN}✓ TensorRT installed: ${TENSORRT_VERSION}${NC}"
else
    echo -e "${RED}✗ TensorRT not found${NC}"
fi

# Check for L4T version
if [ -f "/etc/nv_tegra_release" ]; then
    L4T_VERSION=$(head -1 /etc/nv_tegra_release | awk '{print $5}' | cut -d ',' -f1)
    echo -e "${GREEN}✓ L4T version: ${L4T_VERSION}${NC}"
else
    echo -e "${RED}✗ L4T release information not found${NC}"
fi

# Check for NVIDIA drivers
if [ -d "/usr/lib/aarch64-linux-gnu/tegra" ]; then
    echo -e "${GREEN}✓ NVIDIA Tegra libraries found${NC}"
else
    echo -e "${RED}✗ NVIDIA Tegra libraries not found${NC}"
fi

# Check NVIDIA system files
echo -e "\n${YELLOW}Checking NVIDIA system components...${NC}"
for file in /etc/apt/sources.list.d/nvidia-l4t-apt-source.list /etc/apt/trusted.gpg.d/jetson-cuda-repo.gpg; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓ Found $file${NC}"
    else
        echo -e "${RED}✗ Missing $file${NC}"
    fi
done

# Check for nvpmodel (power management)
if command -v nvpmodel > /dev/null; then
    echo -e "${GREEN}✓ nvpmodel (power management) is available${NC}"
    echo -e "${YELLOW}Current power mode:${NC}"
    nvpmodel -q
else
    echo -e "${RED}✗ nvpmodel not found${NC}"
fi

# Check for jetson_clocks
if [ -f "/usr/bin/jetson_clocks" ]; then
    echo -e "${GREEN}✓ jetson_clocks is available${NC}"
else
    echo -e "${RED}✗ jetson_clocks not found${NC}"
fi

# Check for multimedia APIs
echo -e "\n${YELLOW}Checking for multimedia APIs...${NC}"
if [ -d "/usr/src/jetson_multimedia_api" ]; then
    echo -e "${GREEN}✓ Jetson Multimedia API samples found${NC}"
else
    echo -e "${RED}✗ Jetson Multimedia API samples not found${NC}"
fi

echo -e "\n${YELLOW}Summary:${NC}"
if dpkg -l | grep -q "nvidia-jetpack" || [ -f "/etc/nv_tegra_release" ]; then
    echo -e "${GREEN}✓ NVIDIA JetPack components appear to be installed${NC}"
    echo -e "${YELLOW}For more details, you can check individual components above${NC}"
else
    echo -e "${RED}✗ NVIDIA JetPack doesn't appear to be installed completely${NC}"
    echo -e "${YELLOW}Consider running the JetPack installation script again${NC}"
fi

echo -e "\n====================================================="