#!/bin/bash

# for apt cache
mkdir -p /opt/local/apt-cache
cat << 'EOF' > /etc/apt/sources.list.d/cache.list
deb [trusted=yes] http://console-1.local:3142 noble/
EOF

apt-get update

apt-get install -y --install-recommends linux-generic-hwe-24.04

apt-get install -y ubuntu-drivers-common alsa-utils

# nvidia package install instructions
# https://ubuntu.com/server/docs/how-to/graphics/install-nvidia-drivers/
ubuntu-drivers install --gpgpu nvidia:590-server
apt-get install -y nvidia-utils-590-server