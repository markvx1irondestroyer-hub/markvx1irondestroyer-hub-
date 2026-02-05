#!/bin/bash
# 🧟 MERCURY: THE MASTER INSTALLER (v1.6-FINAL)
# Optimized for Ubuntu/Zorin OS & NVIDIA GTX 750

echo "🚀 Starting Mercury Master Foundation Install..."

# 1. System, NVIDIA Drivers & Emoji Support
sudo apt update && sudo apt upgrade -y
sudo apt install -y fonts-noto-color-emoji ca-certificates curl gnupg
sudo ubuntu-drivers autoinstall

# 2. Docker Engine & NVIDIA Container Toolkit
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update && sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER

# NVIDIA Toolkit configuration
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt update && sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# 3. Directory Setup & Permissions
mkdir -p ~/mercury/config/{jellyfin,jellyseerr,sonarr,radarr,prowlarr,qbittorrent,flaresolverr,tailscale}
sudo mkdir -p /media/linux/Expansion
sudo chown -R $USER:$USER ~/mercury

# 4. Inject Master 'm' Alias
cat << 'EOF' >> ~/.bash_aliases
# --- Mercury Master Control ---
alias gpu='watch -n 1 nvidia-smi --query-gpu=name,temperature.gpu,utilization.gpu,utilization.memory,memory.used,power.draw --format=csv'
alias mercury='cd ~/mercury'

m() {
    case $1 in
        up)     cd ~/mercury && docker compose up -d ;;
        status) docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" ;;
        gpu)    gpu ;;
        ps)     docker ps ;;
        reset)  cd ~/mercury && docker compose down && docker system prune -f && docker compose up -d ;;
        mount)  sudo mount -a && echo "🧟 Vault Refreshed." ;;
        urls)   echo "Jellyfin: http://$(hostname -I | awk '{print $1}'):8096"
                echo "qBittorrent: http://$(hostname -I | awk '{print $1}'):8080"
                echo "Jellyseerr: http://$(hostname -I | awk '{print $1}'):5055" ;;
        heal) 
            echo "🧟 Reviving the Zombie..."
            sudo mount -a
            sudo chown -R $USER:$USER /media/linux/Expansion ~/mercury/config
            cd ~/mercury && docker compose up -d --remove-orphans
            docker system prune -f
            echo "✅ Surgery Complete. System Stable." ;;
        tv)
            echo "📺 --- SAMSUNG TIZEN SIDELOADER ---"
            read -p "Enter your Samsung TV IP address: " TV_IP
            docker run --rm --ulimit nofile=1024:65536 \
              -e JELLYFIN_RELEASE="release-10.8.z" \
              ghcr.io/georift/install-jellyfin-tizen "$TV_IP" ;;
        *)      echo "Usage: m [up|status|gpu|ps|reset|mount|urls|heal|tv]" ;;
    esac
}
EOF

# 5. External Storage "Internal Trick" (FSTAB)
echo ""
read -p "❓ Do you want to set up the Expansion drive (Vault) now? (y/n): " setup_vault
if [[ $setup_vault == "y" ]]; then
    lsblk -f
    echo "⚠️ Copy the UUID for your Expansion drive from the list above."
    read -p "Enter the UUID: " UUID
    sudo cp /etc/fstab /etc/fstab.bak
    echo "UUID=$UUID /media/linux/Expansion auto nosuid,nodev,nofail,x-gvfs-show 0 0" | sudo tee -a /etc/fstab
    sudo mount -a
    echo "✅ Vault integrated."
fi

# 6. Final Sequence: Inject Login Badge & Show Text Art
cat << 'EOF' >> ~/.bashrc
echo -e "\e[32m"
cat << "ZOMBIE"
      .---.
     / @ @ \     🧟 MERCURY MASTER SERVER v1.6
    |  \_  |     -------------------------------
    |   \_ |     Mode: FULL AUTOMATION / MASTER
     \  m  /     Type 'm' for Master Commands
      '---'      
ZOMBIE
echo "nom nom nom brains.. the Master Zombie rises."
echo -e "\e[0m"
EOF

# Clear screen and show the art one last time for the user
clear
echo -e "\e[32m"
cat << "ZOMBIE"
      .---.
     / @ @ \     🧟 MERCURY MASTER INSTALLED
    |  \_  |     -------------------------------
    |   \_ |     All systems integrated.
     \  m  /     Vault setup complete.
      '---'      
ZOMBIE
echo "nom nom nom brains.. The Zombie is ready for you."
echo -e "\e[0m"

echo "Rebooting in 5 seconds to finalize NVIDIA drivers..."
sleep 5
sudo reboot
