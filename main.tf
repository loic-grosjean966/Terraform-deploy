# Point d'entrée : création des machines virtuelles.
#
# Toute la logique de création d'une VM vit dans ./modules/vm. Ce fichier se contente
# de l'appeler une fois par entrée de la variable `vms`, en lui passant les UUID des
# entités Nutanix (cluster, image, subnet).
#
# Pour ajouter ou retirer une VM, il ne faut PAS modifier ce fichier : il suffit
# d'ajouter ou de retirer une entrée dans la map `vms` de terraform.tfvars.

module "vms" {
  # `for_each` crée une instance du module par entrée de la map. L'adresse de la
  # ressource dans le state est donc module.vms["NOM-DE-LA-VM"], stable tant que la
  # clé ne change pas — c'est ce qui permet d'ajouter une VM sans toucher aux autres.
  for_each = var.vms

  source = "./modules/vm"

  name        = each.key # la clé de la map est le nom de la VM
  description = each.value.description

  cluster_ext_id = var.nutanix_cluster_uuid
  image_ext_id   = var.nutanix_image_uuid
  subnet_ext_id  = var.nutanix_subnet_uuid

  num_cores_per_socket = each.value.num_cores_per_socket
  num_sockets          = each.value.num_sockets
  memory_size_bytes    = each.value.memory_size_bytes
  disk_size_bytes      = each.value.disk_size_bytes
  power_state          = each.value.power_state

  ssh_keys        = each.value.ssh_keys
  cloud_init_user = each.value.cloud_init_user

  # Volontairement global et non pris dans la map `vms` : le compte de secours relève
  # d'une politique d'accès uniforme, pas du gabarit d'une VM particulière.
  break_glass_user          = var.break_glass_user
  break_glass_password_hash = var.break_glass_password_hash

  ad_domain      = var.ad_domain
  ad_admin_group = var.ad_admin_group
}
