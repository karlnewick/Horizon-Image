# https://www.packer.io/docs/builders/vmware/vsphere-iso

## vCenter Information ##

variable vcenter_server {
  type = string
  description = "vCenter URL"
  default = "vCenter FQDN"
}

variable username {
  type = string
  description = "The username for authenticating to vCenter."
  default = "svc-packer@vsphere.local"
}

variable password {
  type = string
  description = "VMware123!"
  default= "VMware123!"
}

variable network {
  type = string
  description = "The network segment or port group name to which the primary virtual network adapter will be connected. A full path must be specified if the network is in a network folder."
  default = "Desktop"
}

variable resource_pool {
  type = string
  description = "The vSphere resource pool in which the VM will be created."
  default = "Compute-ResourcePool"
}

variable datacenter {
  type = string
  description = "The vSphere datacenter name. Required if there is more than one datacenter in vCenter."
  default = "LAB"
}

variable cluster {
  type = string
  description = "The vSphere cluster where the target VM is created."
  default = "Compute"
}

variable datastore {
  type = string
  description = "The vSAN, VMFS, or NFS datastore for virtual disk and ISO file storage. Required for clusters, or if the target host has multiple datastores."
  default = "VDi-1-NMB"
}

variable iso_filepath {
  type = string
  description = "The file path within your datastore to your ISO image installation media."
  default = "ISO"
}

variable folder {
  type = string
  description = "The VM folder in which the VM template will be created."
  default = "Templates"
}

variable host {
  type = string
  description = "The ESXi host where target VM is created. A full path must be specified if the host is in a host folder."
  default = "lab-vdi-esxi02.wei-lab.com"
}

## Virtual Machine Information

variable vm_name {
  type = string
  description = "The name of the new VM template to create."
  default = "W10x64_Ent"
}

variable vm_version {
  type = number
  description = "The VM virtual hardware version."
  # https://kb.vmware.com/s/article/1003746
  default = 14
}

variable iso_filename_windows {
  type = string
  description = "The file name of the guest operating system ISO image installation media."
  default = "SW_DVD9_Win_Pro_10_21H2.9_64BIT_English_Pro_Ent_EDU_N_MLF_X23-21974.ISO"
}

variable iso_filename_vmware_tools {
  type = string
  description = "The file name of the VMware Tools for Windows ISO image installation media."
  # https://packages.vmware.com/tools/esx/latest/windows/VMware-tools-windows-11.2.5-17337674.iso
  default = "VMware-Tools-windows-12.1.0-20219665.iso"
}

variable disk_controller_type {
  type = string
  description = "The virtual disk controller type."
  default = "lsilogic-sas"
}
## VM Guest Type
variable guest_os_type {
  type = string
  description = "The VM Guest OS type."
  # https://vdc-download.vmware.com/vmwb-repository/dcr-public/b50dcbbf-051d-4204-a3e7-e1b618c1e384/538cf2ec-b34f-4bae-a332-3820ef9e7773/vim.vm.GuestOsDescriptor.GuestOsIdentifier.html
  default = "windows9_64Guest"
}

## Windows Guest Options
variable answer_file_subdir {
  type = string
  description = "The subdirectory of './windows-10/' where the Windows system preparation (sysprep) XML answer file is stored. See local.answer_file_path"
  # https://docs.microsoft.com/en-us/windows-hardware/manufacture/desktop/use-answer-files-with-sysprep
  default = "windows-10"
}

## WINRM Settings
variable insecure_connection {
  type = bool
  description = "If true, does not validate the vCenter server's TLS certificate."
  default = true
}

variable winrm_password {
  type = string
  description = "VMware1!"
  default = "VMware1!"
}

variable winrm_username {
  type = string
  description = "The username to use to authenticate over WinRM-HTTPS."
  default = "Administrator"
}

locals {
  answer_file_path = "./${var.answer_file_subdir}/autounattend.xml"
  iso_path_vmware_tools = "[${var.datastore}] ${var.iso_filepath}/${var.iso_filename_vmware_tools}"
  iso_path_windows = "[${var.datastore}] ${var.iso_filepath}/${var.iso_filename_windows}"
  vm_name = "${var.vm_name}-${formatdate("MM-DD-YY'-UTC-'hh-mm", timestamp())}"
}
## Specifications for Virtual machine hardware

source vsphere-iso windows-10 {
  CPUs = 4
  RAM = 4096
  RAM_reserve_all = true
  boot_wait = "2m"
  cluster = var.cluster
  
  communicator = "winrm"
  configuration_parameters = {
    "devices.hotplug" = false,
    "svga.autodetect" = true,
    "cloneprep.debug.mode" = true
  }
  convert_to_template = false
  create_snapshot = true
  datacenter = var.datacenter
  datastore = var.datastore
  disable_shutdown = false
  #shutdown_command = "shutdown /r /t 5"

  disk_controller_type = [
    var.disk_controller_type,
  ]
  floppy_files = [
    local.answer_file_path,
    "./provisioners/powershell/Initialize-WinRM.ps1",
    "./provisioners/powershell/Install-VMTools.ps1",
  ]
  remove_cdrom = true
  folder = var.folder
  guest_os_type = var.guest_os_type
  host = var.host
  insecure_connection = var.insecure_connection
  iso_paths = [
    local.iso_path_windows,
    local.iso_path_vmware_tools,
  ]
  network_adapters {
    network = var.network
    network_card = "vmxnet3"
  }
  password = var.password
  resource_pool = var.resource_pool
  
  storage {
    disk_size = 50000
    disk_thin_provisioned = true
  }
  username = var.username
  vcenter_server = var.vcenter_server
  vm_name = local.vm_name
  vm_version = var.vm_version
  winrm_insecure = false
  winrm_password = var.winrm_password
  winrm_timeout = "20m"
  winrm_username = var.winrm_username
  winrm_use_ssl = false
}

build {
  name = "windows-10"
  sources = [
    "source.vsphere-iso.windows-10",
  ]
  provisioner "ansible" {
    playbook_file = "./provisioners/ansible/playbooks/Initial-VM-Creation.yml"
    inventory_directory = "./provisioners/ansible/inventory"
    inventory_file_template = "{{.HostAlias}} ansible_host=${build.Host} ansible_user=${build.User} ansible_port=${build.Port} vcenter_server=${var.vcenter_server}\n"
    keep_inventory_file = false
    user = var.winrm_username
    use_proxy = false
    extra_arguments = [
      "--connection", "winrm",
      "--extra-vars", "ansible_shell_type=powershell ansible_shell_executable=None"
                      ]
  }
}
