#!/usr/bin/env bash
total_mem=$(free -m | awk '/^Mem:/{print $2}')
zram_size=$((total_mem / 2 < 2048 ? 2048 : total_mem / 2))
echo "Configuring zram.service with size: ${zram_size}M"
# Create zram configuration
sudo touch /etc/modules-load.d/zram.conf
echo 'zram' | sudo tee /etc/modules-load.d/zram.conf
sudo touch /etc/modprobe.d/zram.conf
echo "options zram num_devices=1" | sudo tee /etc/modprobe.d/zram.conf
sudo touch /etc/udev/rules.d/99-zram.rules
echo "KERNEL==\"zram0\", ATTR{disksize}=\"${zram_size}M\", TAG+=\"systemd\"" \
  | sudo tee /etc/udev/rules.d/99-zram.rules
sudo touch /etc/systemd/system/zram.service
echo "Installing zram.service"
cat << EOF | sudo tee /etc/systemd/system/zram.service
[Unit]
Description=Swap with zram
After=multi-user.target
[Service]
Type=oneshot 
RemainAfterExit=true
ExecStartPre=/sbin/mkswap /dev/zram0
ExecStart=/sbin/swapon /dev/zram0
ExecStop=/sbin/swapoff /dev/zram0
[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable zram
echo "You'll need to reboot for this to take effect."
