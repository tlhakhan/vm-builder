terraform {
  required_version = "~> 1.9"
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "= 0.9.7"
    }
  }
}

resource "libvirt_pool" "datastore" {
  name = "${var.name}-datastore"
  type = "dir"
  target = {
    path = "/data/datastore/${var.name}"
  }
}

resource "libvirt_volume" "cloud_image" {
  name = "${var.name}-cloud-image"
  pool = libvirt_pool.datastore.name
  target = {
    format = {
      type = "qcow2"
    }
  }
  create = {
    content = {
      url = var.cloud_image_url
    }
  }
}

resource "libvirt_cloudinit_disk" "cloudinit_seed" {
  name      = "${var.name}-cloudinit-seed"
  meta_data = <<-EOF
    instance-id: ${var.name}
    local-hostname: ${var.name}
  EOF

  user_data = templatefile("${path.module}/templates/cloud-init.user-data.yaml", {
    hostname               = var.name
    launch_script          = var.launch_script
    automation_user        = var.automation_user
    automation_user_pubkey = var.automation_user_pubkey
    console_user           = var.console_user
    console_password       = var.console_password
  })

  network_config = <<-EOF
    network:
    version: 2
    ethernets:
      en_interfaces:
        match:
          name: "en*"
        dhcp4: yes
        dhcp6: yes
  EOF
}

resource "libvirt_volume" "cloudinit_disk" {
  name = "${var.name}-cloudinit-disk"
  pool = libvirt_pool.datastore.name
  create = {
    content = {
      url = libvirt_cloudinit_disk.cloudinit_seed.path
    }
  }
}

resource "libvirt_volume" "root_disk" {
  name     = "${var.name}-root-disk"
  capacity = var.disk_sizes_gib[0] * 1024 * 1024 * 1024 // size must be in bytes
  pool     = libvirt_pool.datastore.name
  target = {
    format = {
      type = "qcow2"
    }
  }
  backing_store = {
    path = libvirt_volume.cloud_image.path
    format = {
      type = "qcow2"
    }
  }
}

resource "libvirt_volume" "data_disks" {
  // grab a slice from the list disk_sizes_gib, ignore the first element because its the root disk size
  for_each = { for i, v in slice(var.disk_sizes_gib, 1, length(var.disk_sizes_gib)) : i => v }
  name     = "${var.name}-data-disk-${each.key}"
  capacity = each.value * 1024 * 1024 * 1024 // size must be in bytes
  pool     = libvirt_pool.datastore.name
  target = {
    format = {
      type = "qcow2"
    }
  }
}

locals {
  dev_lookup = ["vdb", "vdc", "vdd", "vde", "vdf", "vdg", "vdh"] // max of 7 additional disks
  additional_disks = [for i, _ in libvirt_volume.data_disks : {
    source = {
      volume = {
        pool   = libvirt_volume.data_disks[i].pool
        volume = libvirt_volume.data_disks[i].name
      }
    }
    driver = {
      type = "qcow2"
    }
    target = {
      dev = local.dev_lookup[i] // used lookup table to convert index into dev names
      bus = "virtio"
    }
  }]
}

resource "libvirt_domain" "machine" {
  name        = var.name
  autostart   = var.autostart
  memory      = var.memory_size_gib * 1024 // memory must be in mib
  memory_unit = "MiB"
  vcpu        = var.cpu_count
  type        = "kvm"

  running = true

  os = {
    type    = "hvm"
    arch    = "x86_64"
    machine = "q35"
    boot_devices = [{
      dev = "hd"
    }]
  }

  features = {
    acpi = true
  }

  devices = {
    consoles = [{
      type        = "pty"
      target_port = "0"
      target_type = "serial"
    }]

    # quirk or bug, cdrom should be first otherwise it results in terraform before/ater apply inconsistencies when using more disks
    # needs more trial and error to find the root cause
    disks = concat([
      {
        device = "cdrom"
        source = {
          volume = {
            pool   = libvirt_volume.cloudinit_disk.pool
            volume = libvirt_volume.cloudinit_disk.name
          }
        }
        target = {
          dev = "sda"
          bus = "sata"
        }
      },
      {
        source = {
          # do not use file, as it results in 'raw' format in the dumpxml output
          # in EFI 'raw' disks were not visible and failed to boot
          volume = {
            pool   = libvirt_volume.root_disk.pool
            volume = libvirt_volume.root_disk.name
          }
        }
        driver = {
          type = "qcow2"
        }
        target = {
          dev = "vda"
          bus = "virtio"
        }
      }
    ], local.additional_disks)

    interfaces = [
      {
        model = {
          type = "virtio"
        }
        source = {
          bridge = {
            bridge = "br0"
          }
        }
      }
    ]

    graphics = [
      {
        spice = {
          auto_port = true
          listeners = [
            {
              address = {}
            }
          ]
        }
      }
    ]

    videos = [
      {
        model = {
          type    = "virtio"
          heads   = 1
          primary = "yes"
        }
      }
    ]

    hostdevs = length(var.pci_devices) > 0 ? [for dev in var.pci_devices : {
      managed = true
      subsys_pci = {
        source = {
          address = {
            domain   = dev.domain
            bus      = dev.bus
            slot     = dev.slot
            function = dev.function
          }
        }
      }
    }] : null
  }

  cpu = {
    mode = "host-passthrough"
  }

}
