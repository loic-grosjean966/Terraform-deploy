# Paramètres d'entrée du module vm.
#
# Les valeurs par défaut définies ici s'appliquent si l'appelant ne passe rien. En
# pratique, le main.tf racine passe toujours toutes les valeurs (issues de la map `vms`),
# donc ce sont les défauts de la variable `vms` dans ../../variables.tf qui s'appliquent.

# --- Identité -------------------------------------------------------------------------

variable "name" {
  description = "Nom de la machine virtuelle"
  type        = string
}

variable "description" {
  description = "Description de la machine virtuelle"
  type        = string
  default     = "Machine virtuelle Nutanix"
}

# --- Gabarit (CPU / RAM / disque) -----------------------------------------------------

variable "num_cores_per_socket" {
  description = "Nombre de cœurs par socket"
  type        = number
  default     = 2
}

variable "num_sockets" {
  description = "Nombre de sockets CPU (vCPU total = num_sockets × num_cores_per_socket)"
  type        = number
  default     = 1
}

variable "memory_size_bytes" {
  description = "Mémoire RAM en octets"
  type        = number
  default     = 8589934592 # 8 Go = 8 × 1024³
}

variable "disk_size_bytes" {
  description = "Taille du disque système en octets. Doit être supérieure ou égale à la taille de l'image source."
  type        = number
  default     = 21474836480 # 20 Go = 20 × 1024³
}

variable "power_state" {
  description = "État d'alimentation : ON ou OFF"
  type        = string
  default     = "ON"
}

variable "boot_order" {
  description = "Ordre de démarrage UEFI. Mettre DISK en premier une fois l'OS installé pour éviter un démarrage réseau inutile."
  type        = list(string)
  default     = ["NETWORK", "DISK", "CDROM"]
}

# --- Références aux entités Nutanix existantes (UUID) ---------------------------------

variable "cluster_ext_id" {
  description = "UUID du cluster Nutanix"
  type        = string
}

variable "image_ext_id" {
  description = "UUID de l'image OS clonée pour le disque système"
  type        = string
}

variable "subnet_ext_id" {
  description = "UUID du subnet auquel rattacher la carte réseau"
  type        = string
}

variable "storage_container_ext_id" {
  description = "UUID du conteneur de stockage hébergeant le disque"
  type        = string
}

# Vestige de l'ancienne version du module, qui ajoutait un lecteur CD avec les pilotes
# VirtIO pour les VMs Windows. Ce disque a été supprimé (les images Linux n'en ont pas
# besoin) : cette variable n'est plus utilisée nulle part et peut être retirée.
variable "virtio_iso_ext_id" {
  description = "UUID de l'image ISO VirtIO (inutilisé)"
  type        = string
  default     = ""
}
