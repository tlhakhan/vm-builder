#!/bin/bash

cat << 'EOF' > /etc/modprobe.d/xe.conf
options xe force_probe=e20c
options xe enable_dc=0
options xe disable_display=true
EOF

mkdir -p /opt/local/apt-cache
cat << 'EOF' > /etc/apt/sources.list.d/cache.list
deb [trusted=yes] http://console-1.local:3142 noble/
EOF

apt-get update

# ubuntu hwe install instructions
# https://canonical-kernel-docs.readthedocs-hosted.com/reference/hwe-kernels/#installing-a-hwe-kernel
apt-get install -y --install-recommends linux-generic-hwe-24.04

# intel package install instructions
# https://dgpu-docs.intel.com/driver/client/overview.html
apt-get install -y software-properties-common 
apt-get install -y libze-intel-gpu1 libze1 intel-metrics-discovery intel-opencl-icd clinfo intel-gsc
apt-get install -y intel-media-va-driver-non-free libmfx-gen1 libvpl2 libvpl-tools libva-glx2 va-driver-all vainfo
apt-get install -y libze-dev intel-ocloc
apt-get install -y libze-intel-gpu-raytracing