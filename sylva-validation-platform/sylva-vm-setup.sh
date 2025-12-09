#!/bin/bash

# This script automates the installation of Docker, pip, PyYAML, yamllint, and yq on Ubuntu.
# It is designed to be run on a fresh Ubuntu installation.
# The script will exit immediately if any command fails.
set -e

# --- Initial System Update and Prerequisite Installation ---
echo "## 🚀 Updating package lists and installing prerequisites... ##"
sudo apt-get update
sudo apt-get install -y ca-certificates curl gnupg wget python3-pip

# --- Docker Installation ---
echo -e "\n## 🐳 Installing Docker... ##"
# Add Docker's official GPG key
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add the Docker repository to Apt sources
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install Docker Engine
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Add the current user to the 'docker' group to run docker commands without sudo
echo -e "\n## 🧑‍💻 Adding current user to the Docker group... ##"
sudo usermod -aG docker $USER
echo "You will need to log out and log back in for the Docker group changes to take effect."

# --- Python Package Installation ---
echo -e "\n## 🐍 Installing Python packages: PyYAML and yamllint... ##"
sudo pip3 install PyYAML yamllint --break-system-packages

# --- yq Installation ---
echo -e "\n## 📜 Installing yq... ##"
# Fetch the latest version for the system's architecture
YQ_ARCH=$(dpkg --print-architecture)
sudo wget "https://github.com/mikefarah/yq/releases/latest/download/yq_linux_${YQ_ARCH}" -O /usr/local/bin/yq
sudo chmod +x /usr/local/bin/yq

# --- Final Verification ---
echo -e "\n################################################################"
echo "## ✅ Installation Complete!                                    ##"
echo "################################################################"
echo -e "\nTo use Docker without sudo, please log out and log back in."
echo "You can verify the installations with the following commands:"
echo "  docker --version"
echo "  pip3 --version"
echo "  yamllint --version"
echo "  yq --version"
echo "  python3 -c \"import yaml; print(f'PyYAML version: {yaml.__version__}')\""
