# Création d'une machine virtuelle Nutanix, via l'API v3 (ressource "classique",
# nutanix_virtual_machine) plutôt que v2 (nutanix_virtual_machine_v2).
#
# Ce module crée UNE VM ; c'est le `for_each` du main.tf racine qui en crée plusieurs.
#
# Pourquoi v3 et pas v2 : avec nutanix_virtual_machine_v2, la tâche de création
# échouait systématiquement côté serveur ("Failed to perform the operation due to an
# internal error", 100% de progression), alors que la même VM se créait sans problème
# depuis l'assistant de Prism Central. Prism Central s'appuie sur l'API v3, plus
# mature ; cette ressource l'utilise directement.

locals {
  # L'API v3 attend la mémoire et la taille du disque en MEBIOCTETS (Mio), pas en
  # octets — contrairement à l'API v2. La conversion se fait ici pour ne pas changer
  # l'unité des variables exposées par ce module (cohérence avec terraform.tfvars).
  memory_size_mib = var.memory_size_bytes / 1024 / 1024
  disk_size_mib   = var.disk_size_bytes / 1024 / 1024

  # Contrairement à l'API v2 (YAML ou JSON acceptés), l'API v3 exige du JSON strict
  # pour ce champ : "Metadata is not in valid json format" sinon, à la création.
  cloud_init_metadata = var.cloud_init_metadata != "" ? var.cloud_init_metadata : jsonencode({
    "instance-id"    = var.name
    "local-hostname" = lower(var.name)
  })

  cloud_init_user_data = replace(templatefile("${path.module}/templates/user-data.yaml.tftpl", {
    user     = var.cloud_init_user
    ssh_keys = var.ssh_keys
  }), "\r\n", "\n")
}

resource "nutanix_virtual_machine" "this" {
  name        = var.name
  description = var.description

  cluster_uuid = var.cluster_ext_id

  # CPU total de la VM = num_sockets × num_vcpus_per_socket
  num_sockets          = var.num_sockets
  num_vcpus_per_socket = var.num_cores_per_socket
  memory_size_mib      = local.memory_size_mib

  # "ON" démarre la VM immédiatement après sa création.
  # Passer une VM existante à "OFF" l'éteint sans la détruire.
  power_state = var.power_state

  boot_type = "UEFI"

  disk_list {
    # Source du disque : clonage de l'image OS. Sans ce bloc, la VM démarrerait sur
    # un disque vide.
    data_source_reference = {
      kind = "image"
      uuid = var.image_ext_id
    }

    # disk_size_mib est ignoré par l'API lors d'un clonage : le disque prend la taille
    # de l'image source au premier apply. Le déclarer ici permet à un second
    # `tofu apply` de détecter l'écart et d'agrandir le disque à la taille voulue —
    # c'est le comportement documenté du provider, pas une limitation de ce module.
    disk_size_mib = local.disk_size_mib

    device_properties {
      device_type = "DISK"
      disk_address = {
        # disk_address est une map(string) : device_index doit être une chaîne.
        device_index = "0"
        adapter_type = "SCSI"
      }
    }

    # Pas de storage_config ici, volontairement : au clonage d'une image, Nutanix
    # place le disque dans le même conteneur que l'image source. Forcer un conteneur
    # différent provoquait un échec de création (déjà observé avec la ressource v2).
  }

  # Carte réseau unique, rattachée au subnet fourni.
  nic_list {
    subnet_uuid = var.subnet_ext_id
  }

  # Personnalisation au premier boot via cloud-init. Sans clé SSH, ces attributs
  # restent null : pas de config drive généré, la VM se crée sans personnalisation
  # (elle serait de toute façon inaccessible : le compte créé a lock_passwd = true).
  guest_customization_cloud_init_user_data = length(var.ssh_keys) > 0 ? base64encode(local.cloud_init_user_data) : null
  guest_customization_cloud_init_meta_data = length(var.ssh_keys) > 0 ? base64encode(local.cloud_init_metadata) : null
}
