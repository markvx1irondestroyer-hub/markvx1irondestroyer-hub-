#!/bin/bash
# 🧟 MERCURY: UNIVERSAL GPU SWAP TOOL
echo "🧪 Adjusting Mercury for non-NVIDIA hardware..."

# 1. Install universal monitoring and drivers
sudo apt update
sudo apt install -y nvtop mesa-va-drivers intel-media-va-driver-non-free

# 2. Add the user to necessary hardware groups
sudo usermod -aG video $USER
sudo usermod -aG render $USER

# 3. Fix hardware permissions for the render device
sudo chmod 666 /dev/dri/renderD128

# 4. Update the 'm' alias to use universal monitoring
sed -i "s/alias gpu=.*/alias gpu='nvtop'/" ~/.bash_aliases
source ~/.bash_aliases

echo "✅ Hardware drivers ready. Please update your docker-compose.yml next!"
