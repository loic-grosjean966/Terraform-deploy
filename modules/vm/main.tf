# Création d'UNE machine virtuelle Nutanix via l'API v3 (`nutanix_virtual_machine`).
# C'est le `for_each` du main.tf racine qui en crée plusieurs.
#
# Le choix de l'API v3 plutôt que v4, et les autres décisions non évidentes de ce fichier,
# sont expliqués dans le README, section "Choix techniques".

locals {
  # L'API v3 attend des MEBIOCTETS. Les variables du module restent en octets pour
  # rester cohérentes avec terraform.tfvars.
  memory_size_mib = var.memory_size_bytes / 1024 / 1024
  disk_size_mib   = var.disk_size_bytes / 1024 / 1024

  # Format OpenStack ConfigDrive v2, en JSON strict — pas du NoCloud, pas du YAML.
  # "uuid" est obligatoire : sans elle, cloud-init rejette le datasource et n'applique
  # RIEN. Voir README, section "Choix techniques".
  cloud_init_metadata = var.cloud_init_metadata != "" ? var.cloud_init_metadata : jsonencode({
    # uuidv5 garde l'UUID stable d'un apply à l'autre : cloud-init ne rejoue donc pas
    # ses modules "per instance" à chaque redéploiement.
    "uuid"     = uuidv5("dns", lower(var.name))
    "hostname" = lower(var.name)
    "name"     = lower(var.name)
  })

  # Le replace() neutralise les CRLF que Windows introduirait : cloud-init ignore
  # silencieusement un user-data dont les retours à la ligne sont mal formés.
  cloud_init_user_data = replace(templatefile("${path.module}/templates/user-data.yaml.tftpl", {
    user                      = var.cloud_init_user
    hostname                  = lower(var.name)
    ssh_keys                  = var.ssh_keys
    break_glass_user          = var.break_glass_user
    break_glass_password_hash = var.break_glass_password_hash
    ad_domain                 = var.ad_domain
    ad_admin_group            = var.ad_admin_group
  }), "\r\n", "\n")
}

resource "nutanix_virtual_machine" "this" {
  name        = var.name
  description = var.description

  cluster_uuid = var.cluster_ext_id

  # vCPU total = num_sockets × num_vcpus_per_socket
  num_sockets          = var.num_sockets
  num_vcpus_per_socket = var.num_cores_per_socket
  memory_size_mib      = local.memory_size_mib

  # "OFF" sur une VM existante l'éteint sans la détruire.
  power_state = var.power_state

  boot_type = "UEFI"

  disk_list {
    # Clonage de l'image OS. Sans ce bloc, la VM démarrerait sur un disque vide.
    data_source_reference = {
      kind = "image"
      uuid = var.image_ext_id
    }

    # Au clonage, l'API donne d'abord au disque la taille de l'image source ; c'est un
    # second apply qui détecte l'écart et l'agrandit. Voir README, tableau des paramètres.
    disk_size_mib = local.disk_size_mib

    device_properties {
      device_type = "DISK"
      disk_address = {
        # map(string) : device_index doit être une chaîne, pas un nombre.
        device_index = "0"
        adapter_type = "SCSI"
      }
    }

    # Pas de storage_config volontairement : au clonage, Nutanix impose le conteneur de
    # l'image source, et en forcer un autre fait échouer la création.
  }

  # Carte réseau unique, rattachée au subnet fourni.
  nic_list {
    subnet_uuid = var.subnet_ext_id
  }

  # Personnalisation au premier démarrage. Toujours renseignée, même sans clé SSH :
  # le hostname, le clavier et la préparation AD s'appliquent indépendamment.
  guest_customization_cloud_init_user_data = base64encode(local.cloud_init_user_data)
  guest_customization_cloud_init_meta_data = base64encode(local.cloud_init_metadata)
}
