variable nutanix_username {
  description = "Nutanix username"
  type        = string
  sensitive   = true
}

variable nutanix_password {
  description = "Nutanix password"
  type        = string
  sensitive   = true
}

variable nutanix_endpoint {
  description = "Nutanix endpoint URL"
  type        = string
}

variable nutanix_port {
  description = "Nutanix port"
  type        = number
  default     = 9440
}

variable nutanix_insecure {
  description = "Skip SSL verification"
  type        = bool
  default     = true
}

variable nutanix_cluster_uuid {
  description = "Nutanix cluster ID"
  type        = string
}

variable nutanix_image_uuid {
  description = "Nutanix image UUID"
  type        = string
}

variable nutanix_subnet_uuid {
  description = "Nutanix subnet UUID"
  type        = string
}

variable nutanix_storage_container_uuid {
  description = "UUID du conteneur de stockage Nutanix"
  type        = string
}

variable subnet_ext_id {
  description = "UUID du subnet à utiliser par les VMs"
  type        = string
  default     = ""
}

variable existing_subnet_ext_id {
  description = "UUID du subnet VLAN existant à réutiliser"
  type        = string
  default     = ""
}

variable dev_subnet_ext_id {
  description = "UUID du subnet VLAN de développement à réutiliser"
  type        = string
  default     = ""
}

variable vms {
  description = "Map of Nutanix VMs to create"
  type = map(object({
    description          = optional(string, "Machine virtuelle Nutanix")
    num_cores_per_socket = optional(number, 2)
    num_sockets          = optional(number, 1)
    memory_size_bytes    = optional(number, 8 * pow(1024, 3))
    disk_size_bytes      = optional(number, 20 * pow(1024, 3))
    power_state          = optional(string, "ON")
    boot_order           = optional(list(string), ["NETWORK", "DISK", "CDROM"])
  }))
  default = {}
}

variable vm_name {
  description = "Name of the virtual machine"
  type        = string
  default     = "vm-demo"
}
