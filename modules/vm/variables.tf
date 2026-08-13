# Paramètres d'entrée du module vm.
#
# Descriptions volontairement brèves : la documentation de référence (valeurs attendues,
# pièges, exemples) vit dans ../../variables.tf et dans le README. La dupliquer ici
# garantissait de la voir diverger.
#
# Les défauts ci-dessous ne s'appliquent en pratique jamais : le main.tf racine passe
# toujours toutes les valeurs, issues de la variable `vms`.

# --- Identité ---------------------------------------------------------------------------

variable "name" {
  description = "Nom de la machine virtuelle"
  type        = string
}

variable "description" {
  description = "Description de la machine virtuelle"
  type        = string
  default     = "Machine virtuelle Nutanix"
}

# --- Accès ------------------------------------------------------------------------------
# Voir README, section "Modèle d'accès".

variable "ssh_keys" {
  description = "Clés publiques SSH autorisées sur le compte cloud_init_user"
  type        = list(string)
  default     = []
}

variable "cloud_init_user" {
  description = "Nom de l'utilisateur créé par cloud-init"
  type        = string
  default     = "ubuntu"
}

variable "break_glass_user" {
  description = "Nom du compte de secours accessible en console"
  type        = string
  default     = "secours"
}

variable "break_glass_password_hash" {
  description = "Hachage SHA-512 du mot de passe du compte de secours. Vide = pas de compte de secours."
  type        = string
  sensitive   = true
  default     = ""
}

variable "ad_domain" {
  description = "Domaine Active Directory. Vide = pas de préparation AD. La jonction reste manuelle."
  type        = string
  default     = ""
}

variable "ad_admin_group" {
  description = "Groupe AD recevant les droits sudo. Vide = aucun droit sudo via l'annuaire."
  type        = string
  default     = ""
}

# --- Cloud-init -------------------------------------------------------------------------

variable "cloud_init_metadata" {
  description = "Meta-data cloud-init en JSON strict, au format OpenStack ConfigDrive. Vide = généré depuis le nom de la VM."
  type        = string
  default     = ""
}

# --- Gabarit (CPU / RAM / disque) --------------------------------------------------------

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
  description = "Taille du disque système en octets. Doit être ≥ à la taille de l'image source."
  type        = number
  default     = 21474836480 # 20 Go = 20 × 1024³
}

variable "power_state" {
  description = "État d'alimentation : ON ou OFF"
  type        = string
  default     = "ON"
}

# --- Références aux entités Nutanix existantes (UUID) ------------------------------------

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
