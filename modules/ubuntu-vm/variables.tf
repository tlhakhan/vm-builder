variable "name" {
  type        = string
  description = "The name of the virtual machine"
}

variable "memory_size_gib" {
  type    = number
  default = 2
}

variable "disk_sizes_gib" {
  type    = list(number)
  default = [8]
}

variable "cpu_count" {
  type    = number
  default = 2
}

variable "launch_script" {
  type        = string
  default     = ""
  description = "A shell script to run on the machine after cloud-init has finished"
}

variable "console_user" {
  type    = string
  default = "ubuntu"
}

variable "console_password" {
  type      = string
  sensitive = true
}

variable "automation_user" {
  type    = string
  default = "ubuntu"
}

variable "automation_user_pubkey" {
  type = string
}

variable "pci_devices" {
  type = list(object({
    domain   = number
    bus      = number
    slot     = number
    function = number
  }))
  default     = []
  description = "List of PCI BDF (Bus, Device, Function) address components for passthrough, including domain."
}

variable "autostart" {
  type        = bool
  default     = true
  description = "Autostart the VM on hypervisor boot"
}

variable "cloud_image_url" {
  type    = string
  default = "https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
}