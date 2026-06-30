variable "name" {
  description = "Nom de la machine virtuelle"
  type        = string
}

variable "description" {
  description = "Description de la machine virtuelle"
  type        = string
  default     = "Machine virtuelle Nutanix"
}

variable "num_cores_per_socket" {
  description = "Nombre de cœurs par socket"
  type        = number
  default     = 2
}

variable "num_sockets" {
  description = "Nombre de sockets CPU"
  type        = number
  default     = 1
}

variable "memory_size_bytes" {
  description = "Mémoire RAM de la VM en octets"
  type        = number
  default     = 8 * pow(1024, 3)
}

variable "power_state" {
  description = "État de puissance de la VM"
  type        = string
  default     = "ON"
}

variable "cluster_ext_id" {
  description = "UUID du cluster Nutanix"
  type        = string
}

variable "image_ext_id" {
  description = "UUID de l'image de base"
  type        = string
}

variable "subnet_ext_id" {
  description = "UUID du subnet"
  type        = string
}

variable "storage_container_ext_id" {
  description = "UUID du conteneur de stockage"
  type        = string
}

variable "disk_size_bytes" {
  description = "Taille du disque principal en octets"
  type        = number
  default     = 20 * pow(1024, 3)
}

variable "boot_order" {
  description = "Ordre de démarrage de la VM"
  type        = list(string)
  default     = ["NETWORK", "DISK", "CDROM"]
}
