variable "nutanix_username" {
  description = "Nutanix username"
  type        = string
  sensitive   = true
}

variable "nutanix_password" {
  description = "Nutanix password"
  type        = string
  sensitive   = true
}

variable "nutanix_endpoint" {
  description = "Nutanix endpoint URL"
  type        = string
}

variable "nutanix_port" {
  description = "Nutanix port"
  type        = number
  default     = 9440
}

variable "nutanix_insecure" {
  description = "Skip SSL verification"
  type        = bool
  default     = true
}

variable "nutanix_cluster_uuid" {
  description = "Nutanix cluster ID"
  type        = string
}

variable "nutanix_image_uuid" {
  description = "Nutanix image UUID"
  type        = string
}

variable "nutanix_subnet_uuid" {
  description = "UUID du subnet existant utilisé par les VMs"
  type        = string
}

variable "nutanix_storage_container_uuid" {
  description = "UUID du conteneur de stockage Nutanix"
  type        = string
}

variable "vms" {
  description = "Map of Nutanix VMs to create"
  type = map(object({
    description          = optional(string, "Machine virtuelle Nutanix")
    num_cores_per_socket = optional(number, 2)
    num_sockets          = optional(number, 1)
    memory_size_bytes    = optional(number, 8589934592)
    disk_size_bytes      = optional(number, 21474836480)
    power_state          = optional(string, "ON")
    boot_order           = optional(list(string), ["NETWORK", "DISK", "CDROM"])
  }))
  default = {}
}
