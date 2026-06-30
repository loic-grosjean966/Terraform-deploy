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

variable vm_name {
  description = "Name of the virtual machine"
  type        = string
  default     = "vm-demo"
}