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
# --- Connexion via SSH -------------------------------------------------------------------
variable "ssh_keys" {
  description = "Liste des clés SSH autorisées pour se connecter à la VM"
  type        = list(string)
  default     = []
}
# --- Cloud-init ---------------------------------------------------------------------
variable "cloud_init_user" {
  description = "Nom de l'utilisateur créé par cloud-init"
  type        = string
  default     = "ubuntu"
}

variable "cloud_init_metadata" {
  description = "Contenu du fichier cloud-init meta-data, en JSON strict (l'API Nutanix rejette le YAML ici). Vide = généré automatiquement depuis le nom de la VM."
  type        = string
  default     = ""
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
