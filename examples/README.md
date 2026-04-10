# Examples

## intel_gpu_setup.sh

Sets up Intel GPU support on an Ubuntu 24.04 VM:

1. Configures the `xe` kernel module — force-probes device ID `e20c` (Intel Arc B570 GPU), disables display output and DC power states for headless compute use.
2. Adds a local apt archives cache as a package source; see below for how to build your own.
3. Installs the HWE kernel (`linux-generic-hwe-24.04`) — required to resolve a kernel bug ([bugzilla.kernel.org/show_bug.cgi?id=220823](https://bugzilla.kernel.org/show_bug.cgi?id=220823)) affecting the `xe` driver on the generic kernel shipped with the Ubuntu 24.04 server image. See the [HWE kernel install instructions](https://canonical-kernel-docs.readthedocs-hosted.com/reference/hwe-kernels/#installing-a-hwe-kernel) for more details.
4. Installs the Intel GPU user-space drivers and compute stack: OpenCL ICD, Level Zero runtime, media/video acceleration (VA-API, VPL), GSC firmware tools, and ray-tracing support. See the [Intel GPU driver install instructions](https://dgpu-docs.intel.com/driver/client/overview.html) for more details.

## nvidia_gpu_setup.sh

Sets up NVIDIA GPU support on an Ubuntu 24.04 VM:

1. Adds a local apt archives cache as a package source; see below for how to build your own.
2. Installs the HWE kernel (`linux-generic-hwe-24.04`) for updated hardware support.
3. Installs `ubuntu-drivers-common` and `alsa-utils`, then uses `ubuntu-drivers` to install the NVIDIA 590 server driver (`nvidia:590-server`). See the [Ubuntu NVIDIA driver install instructions](https://ubuntu.com/server/docs/how-to/graphics/install-nvidia-drivers/) for more details.
4. Installs `nvidia-utils-590-server` for GPU management utilities (e.g. `nvidia-smi`).

### Building a local apt cache

If you want to avoid re-downloading packages on every VM build, you can create a simple local apt mirror:

1. **Collect the `.deb` files** from a machine that has already downloaded them:
   ```bash
   cp /var/cache/apt/archives/*.deb /srv/apt-cache/
   ```

2. **Generate the package index** using `dpkg-scanpackages`:
   ```bash
   cd /srv/apt-cache
   dpkg-scanpackages . /dev/null | gzip -9c > Packages.gz
   ```

3. **Serve it over HTTP** — any simple HTTP server works, for example:
   ```bash
   python3 -m http.server 3142 --directory /srv/apt-cache
   ```
   Or with nginx/caddy pointed at `/srv/apt-cache`.

4. **Reference it in sources.list** on the target VM:
   ```
   deb [trusted=yes] http://<your-host>:3142 ./
   ```

The `trusted=yes` option skips GPG signature verification, which is fine for an internal cache on a trusted network.
