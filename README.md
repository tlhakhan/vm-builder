# README
A repository to help build virtual machines on my servers.

## Pre-requiste packages for Terraform execution host
```
sudo apt-get update 
sudo apt-get install -y mkisofs xsltproc 
```

### Ease of use
Create a `terraform.tfvars` and populate the needed variables.  See example below.

```hcl
vm_name            = "ubuntu"
vm_cpu_count       = 6
vm_memory_size_gib = 12
vm_disk_sizes_gib  = [64, 64, 64, 64, 64, 64, 64, 64]

## for direct console access for the new VMs
vm_console_user     = "ubuntu"
vm_console_password = "ubuntu"

## for remote SSH access for the new VMs
vm_automation_user        = "ubuntu"
vm_automation_user_pubkey = "ssh-rsa ..long pub key string here.."

## optional: PCI devices to pass through (e.g. GPU and its audio function)
## see the "PCI Passthrough" section below for how to find eligible devices
pci_devices = [
  { domain = 0, bus = 1, slot = 0, function = 0 },
  { domain = 0, bus = 1, slot = 0, function = 1 },
]
```

### PCI Passthrough

Devices must be bound to the `vfio-pci` driver on the host before they can be passed through to a VM. To find eligible devices, run:

```
lspci -knn
```

Look for devices where `Kernel driver in use` is `vfio-pci`, for example:

```
01:00.0 VGA compatible controller [0300]: NVIDIA Corporation ... [10de:2684]
        Kernel driver in use: vfio-pci
01:00.1 Audio device [0403]: NVIDIA Corporation ... [10de:22ba]
        Kernel driver in use: vfio-pci
```

The address before the device name (e.g. `01:00.0`) is the BDF — `bus:device(slot).function` in hexadecimal. Convert each component to decimal when populating `pci_devices`:

```
01:00.0  →  { domain = 0, bus = 1, slot = 0, function = 0 }
01:00.1  →  { domain = 0, bus = 1, slot = 0, function = 1 }
```

If a device still shows its native driver (e.g. `nvidia`, `snd_hda_intel`) instead of `vfio-pci`, it has not been bound for passthrough yet. Binding is typically done by adding the device IDs to the `vfio-pci` kernel module via `/etc/modprobe.d/` and updating the initramfs.

### Helper commands
- Use `virsh list` to see all the running VMs, use `--all` to see any shutdown VMs.
- Use `virsh console <vm name>` to connect to the VM's console, use control+] to break out of the console.

```
ubuntu@sparkle-1:~/vm-builder$ virsh list
 Id   Name       State
--------------------------
 2    code-0     running
 3    k8s-0      running
 4    k8s-1      running
 5    k8s-2      running
 28   ubuntu-0   running

ubuntu@sparkle-1:~/vm-builder$ virsh console ubuntu-0
Connected to domain 'ubuntu-0'
Escape character is ^] (Ctrl + ])
ubuntu-0 login: ubuntu
Password:
...
...

root@ubuntu-0:~# lsblk
NAME    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sr0      11:0    1   44K  0 rom
vda     253:0    0   64G  0 disk
├─vda1  253:1    0   63G  0 part /
├─vda14 253:14   0    4M  0 part
├─vda15 253:15   0  106M  0 part /boot/efi
└─vda16 259:0    0  913M  0 part /boot
vdb     253:16   0   64G  0 disk
vdc     253:32   0   64G  0 disk
vdd     253:48   0   64G  0 disk
vde     253:64   0   64G  0 disk
vdf     253:80   0   64G  0 disk
vdg     253:96   0   64G  0 disk
vdh     253:112  0   64G  0 disk

```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_libvirt"></a> [libvirt](#requirement\_libvirt) | ~>0.9 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_ubuntu-vm"></a> [ubuntu-vm](#module\_ubuntu-vm) | ./modules/ubuntu-vm | n/a |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_pci_devices"></a> [pci\_devices](#input\_pci\_devices) | List of PCI BDF (Bus, Device, Function) address components for passthrough, including domain. | `list(object({ domain = number, bus = number, slot = number, function = number }))` | `[]` | no |
| <a name="input_vm_automation_user"></a> [vm\_automation\_user](#input\_vm\_automation\_user) | The username of the remote SSH user | `string` | n/a | yes |
| <a name="input_vm_automation_user_pubkey"></a> [vm\_automation\_user\_pubkey](#input\_vm\_automation\_user\_pubkey) | The SSH public key of the remote SSH user | `string` | n/a | yes |
| <a name="input_vm_cloud_image_url"></a> [vm\_cloud\_image\_url](#input\_vm\_cloud\_image\_url) | The URL to the cloud image suitable for the selected VM operating system | `string` | n/a | yes |
| <a name="input_vm_console_password"></a> [vm\_console\_password](#input\_vm\_console\_password) | The password of the console user | `string` | n/a | yes |
| <a name="input_vm_console_user"></a> [vm\_console\_user](#input\_vm\_console\_user) | The username of the console user | `string` | n/a | yes |
| <a name="input_vm_cpu_count"></a> [vm\_cpu\_count](#input\_vm\_cpu\_count) | The CPU count of the VM(s) | `number` | `2` | no |
| <a name="input_vm_disk_sizes_gib"></a> [vm\_disk\_sizes\_gib](#input\_vm\_disk\_sizes\_gib) | The disk size of the VM(s) in GiB, the first element is the root disk size, followed by data disks if any, with max of 8 disks. | `list(number)` | <pre>[<br/>  48<br/>]</pre> | no |
| <a name="input_vm_memory_size_gib"></a> [vm\_memory\_size\_gib](#input\_vm\_memory\_size\_gib) | The memory size of the VM(s) in GiB | `number` | `4` | no |
| <a name="input_vm_name"></a> [vm\_name](#input\_vm\_name) | The name to give to the VM(s) | `string` | `"vm"` | no |
<!-- END_TF_DOCS -->
