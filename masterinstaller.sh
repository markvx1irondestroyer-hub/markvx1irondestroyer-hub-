#!/bin/bash
# 🧟 MERCURY: THE ALL-IN-ONE MASTER INSTALLER
# Optimized for Ubuntu/Zorin OS & NVIDIA GTX 750

echo "🚀 Starting Mercury Foundation Install..."

# 1. System & NVIDIA Drivers
# [span_5](start_span)Automatically identifies and installs the best driver for the GTX 750 or similar[span_5](end_span).
sudo apt update && sudo apt upgrade -y
sudo ubuntu-drivers autoinstall

# 2. Docker Engine & NVIDIA Container Toolkit
# [span_6](start_span)Sets up the container environment and enables GPU passthrough[span_6](end_span).
sudo apt-get install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt update && sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
sudo usermod -aG docker $USER

# [span_7](start_span)NVIDIA Container Toolkit setup[span_7](end_span).
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt update && sudo apt-get install -y nvidia-container-toolkit
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# 3. Directory Creation & Permissions
# [span_8](start_span)Ensures paths for Jellyfin, Radarr, Sonarr, etc. are ready[span_8](end_span).
mkdir -p ~/mercury/config/{jellyfin,jellyseerr,sonarr,radarr,prowlarr,qbittorrent,flaresolverr,tailscale}
sudo mkdir -p /media/linux/Expansion
sudo chown -R $USER:$USER ~/mercury

# 4. [span_9](start_span)Optional: Expansion Drive "Internal Trick"[span_9](end_span)
echo ""
read -p "❓ Do you want to configure the Expansion drive (Vault) now? (y/n): " setup_vault
if [[ $setup_vault == "y" ]]; then
    lsblk -f
    [span_10](start_span)echo "⚠️ Copy the UUID for your Expansion drive from the list above[span_10](end_span)."
    read -p "Enter the UUID: " UUID
    sudo cp /etc/fstab /etc/fstab.bak
    # [span_11](start_span)Adds nofail to ensure system boots even if drive is missing[span_11](end_span).
    echo "UUID=$UUID /media/linux/Expansion auto nosuid,nodev,nofail,x-gvfs-show 0 0" | sudo tee -a /etc/fstab
    sudo mount -a
    echo "✅ Expansion Drive integrated."
fi

# 5. [span_12](start_span)[span_13](start_span)Inject Master 'm' Command[span_12](end_span)[span_13](end_span)
cat << 'EOF' >> ~/.bash_aliases
# --- Mercury Master Control ---
alias gpu='watch -n 1 nvidia-smi --query-gpu=name,temperature.gpu,utilization.gpu,utilization.memory,memory.used,power.draw --format=csv'
alias mercury='cd ~/mercury'

m() {
    case $1 in
        up)     cd ~/mercury && docker compose up -d ;;
        status) bash ~/mercury/status.sh ;;
        gpu)    gpu ;;
        ps)     docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" ;;
        reset)  cd ~/mercury && docker compose down && docker system prune -f && docker compose up -d ;;
        mount)  sudo mount -a && echo "🧟 Vault Refreshed." ;;
        urls)   echo "Jellyfin: http://$(hostname -I | awk '{print $1}'):8096"
                echo "qBittorrent: http://$(hostname -I | awk '{print $1}'):8080"
                echo "Jellyseerr: http://$(hostname -I | awk '{print $1}'):5055" ;;
        *)      echo "Usage: m [up|status|gpu|ps|reset|mount|urls]" ;;
    esac
}
EOF

echo "🧟 Mercury Core Installed. Rebooting in 5 seconds to finalize drivers..."
sleep 5
sudo reboot
