# Variables d'entrée de la configuration.
#
# Aucune valeur n'est écrite ici : elles sont renseignées dans terraform.tfvars, qui
# n'est pas versionné (il contient les identifiants Prism Central).
# Partir de terraform.tfvars.example pour le créer.
#
# Où trouver les UUID ? Dans Prism Central, ouvrez l'entité concernée : l'UUID apparaît
# dans l'URL de la page. En SSH sur une CVM : `ncli cluster info` (cluster),
# `acli net.list` (subnets), `acli image.list` (images),
# `ncli storagecontainer list` (conteneurs de stockage).

# --- Connexion à Prism Central -------------------------------------------------------

variable "nutanix_username" {
  description = "Identifiant Prism Central"
  type        = string
  sensitive   = true # masqué dans les sorties de tofu (mais présent en clair dans le state)
}

variable "nutanix_password" {
  description = "Mot de passe Prism Central"
  type        = string
  sensitive   = true
}

variable "nutanix_endpoint" {
  # IP ou FQDN seul (ex. "172.20.0.200") : ni schéma https://, ni port — le port est
  # passé séparément via nutanix_port. Une URL complète fait échouer les appels API.
  description = "VIP du cluster Prism Central, sous forme d'IP ou de FQDN"
  type        = string
}

variable "nutanix_port" {
  description = "Port de l'API Nutanix"
  type        = number
  default     = 9440
}

variable "nutanix_insecure" {
  description = "Ignorer la validation du certificat SSL. Nécessaire tant que Prism Central utilise un certificat auto-signé."
  type        = bool
  default     = true
}

# --- Entités Nutanix utilisées par les VMs -------------------------------------------
# Ces entités doivent déjà exister dans Nutanix : cette configuration ne les crée pas,
# elle ne fait que les référencer.

variable "nutanix_cluster_uuid" {
  description = "UUID du cluster sur lequel les VMs sont créées"
  type        = string
}

variable "nutanix_image_uuid" {
  description = "UUID de l'image OS clonée pour créer le disque système des VMs"
  type        = string
}

variable "nutanix_subnet_uuid" {
  description = "UUID du subnet existant auquel les VMs sont rattachées"
  type        = string
}

variable "nutanix_storage_container_uuid" {
  description = "UUID du conteneur de stockage qui héberge les disques des VMs"
  type        = string
}

# --- VMs à déployer -------------------------------------------------------------------

variable "vms" {
  # La clé de la map est le NOM de la VM dans Nutanix ; la valeur décrit son gabarit.
  # Tous les champs sont optionnels sauf la clé : une VM déclarée avec `{}` utilisera
  # les valeurs par défaut ci-dessous (2 vCPU, 8 Go de RAM, 20 Go de disque).
  #
  # Attention : renommer une clé n'est pas un renommage pour OpenTofu, mais une
  # destruction suivie d'une création. Le disque de l'ancienne VM sera perdu.
  #
  # Exemple :
  #   vms = {
  #     "SRV-APP-01" = { description = "Serveur applicatif", num_sockets = 2 }
  #     "SRV-APP-02" = {}
  #   }
  description = "VMs à créer, indexées par nom"

  type = map(object({
    description          = optional(string, "Machine virtuelle Nutanix")
    num_cores_per_socket = optional(number, 2)
    num_sockets          = optional(number, 1)
    memory_size_bytes    = optional(number, 8589934592)  # 8 Go — la valeur doit être en OCTETS
    disk_size_bytes      = optional(number, 21474836480) # 20 Go — idem
    power_state          = optional(string, "ON")        # "ON" ou "OFF"
    boot_order           = optional(list(string), ["NETWORK", "DISK", "CDROM"])
  }))

  default = {}
}
