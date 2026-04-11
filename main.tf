terraform {
  required_providers {
    libvirt = {
      source  = "dmacvicar/libvirt"
      version = "~>0.9"
    }
  }

  backend "local" {
    path = "terraform.tfstate"
  }

}

provider "libvirt" {
  uri = "qemu:///system"
}

module "ubuntu-vm" {
  source = "./modules/ubuntu-vm"
  name   = var.vm_name

  cloud_image_url = var.vm_cloud_image_url

  automation_user        = var.vm_automation_user
  automation_user_pubkey = var.vm_automation_user_pubkey

  console_user     = var.vm_console_user
  console_password = var.vm_console_password

  # vm settings
  cpu_count       = var.vm_cpu_count
  memory_size_gib = var.vm_memory_size_gib
  disk_sizes_gib  = var.vm_disk_sizes_gib

  # gpu settings
  pci_devices = var.pci_devices

  launch_script = fileexists("${path.module}/launch_script.sh") ? file("${path.module}/launch_script.sh") : ""
}
