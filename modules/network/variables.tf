variable "name" {
  description = "Nom du subnet"
  type        = string
}

variable "description" {
  description = "Description du subnet"
  type        = string
  default     = "Subnet Nutanix"
}

variable "subnet_type" {
  description = "Type de subnet (VLAN ou OVERLAY)"
  type        = string
  default     = "VLAN"
}

variable "network_id" {
  description = "ID réseau VLAN"
  type        = number
}

variable "cluster_reference" {
  description = "UUID du cluster"
  type        = string
}

variable "ipv4_network" {
  description = "Réseau IPv4 du subnet"
  type        = string
}

variable "ipv4_prefix_length" {
  description = "Masque CIDR du subnet"
  type        = number
}

variable "default_gateway_ip" {
  description = "Passerelle par défaut"
  type        = string
}

variable "pool_start_ip" {
  description = "Première IP du pool DHCP"
  type        = string
}

variable "pool_end_ip" {
  description = "Dernière IP du pool DHCP"
  type        = string
}
