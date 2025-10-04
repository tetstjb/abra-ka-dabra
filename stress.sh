#!/bin/bash

# Part 1: iptables Configuration
echo "Configuring iptables..."

# Step 1: Disable and Flush iptables
echo "Disabling and flushing iptables..."
sudo systemctl stop iptables
sudo systemctl disable iptables
sudo iptables -F
sudo iptables -X
sudo iptables -t nat -F
sudo iptables -t nat -X
sudo iptables -t mangle -F
sudo iptables -t mangle -X
sudo iptables -P INPUT ACCEPT
sudo iptables -P FORWARD ACCEPT
sudo iptables -P OUTPUT ACCEPT

# Step 2: Remove iptables
echo "Removing iptables..."
sudo apt purge iptables -y

# Step 3: Install iptables
echo "Updating..."
sudo apt update && sudo apt dist-upgrade -y 

# Part 2: RAM Stress Test Setup
echo "Setting up RAM stress test..."

# Install stress-ng
sudo apt install stress-ng -y

# Create the RAM stress test script
cat << 'EOF' | sudo tee /usr/local/bin/ram_stress_test.sh
#!/bin/bash

# RAM Stress Test using stress-ng
cpu_count=$(nproc)  # You may use an alternative method if nproc doesn't work
half_cpu_count=$((cpu_count / 2))
/usr/bin/stress-ng --vm "$half_cpu_count" --vm-bytes 45% -t 5m -q
EOF

# Make the RAM stress test script executable
sudo chmod +x /usr/local/bin/ram_stress_test.sh

# Create the systemd service file for the RAM stress test
cat << 'EOF' | sudo tee /etc/systemd/system/ram_stress_test.service
[Unit]
Description=RAM Stress Test

[Service]
Type=oneshot
ExecStart=/usr/local/bin/ram_stress_test.sh
EOF

# Create the systemd timer file for the RAM stress test
cat << 'EOF' | sudo tee /etc/systemd/system/ram_stress_test.timer
[Unit]
Description=Run RAM Stress Test every 15 minutes

[Timer]
OnCalendar=*-*-* 0,1,2,4,5,6,19,20,21,22,23:0,15,30,45
Persistent=true

[Install]
WantedBy=timers.target
EOF

# Reload systemd manager configuration
sudo systemctl daemon-reload

# Enable and start the timer
echo "Enabling and starting the timer..."
sudo systemctl enable ram_stress_test.timer
sudo systemctl start ram_stress_test.timer
sudo systemctl status ram_stress_test.timer

# Part 3: Timezone Configuration
echo "Setting timezone to Asia/Kolkata..."
sudo timedatectl set-timezone Asia/Kolkata

# Display completion message
echo "Setup completed. The RAM stress test is scheduled to run every 15 minutes, and iptables rules are applied."


# --- Step 3: Reboot at the end ---
echo "🔁 Rebooting system in 5 seconds..."
sleep 5
sudo reboot
