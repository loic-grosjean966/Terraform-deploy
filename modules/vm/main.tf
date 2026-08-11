# Création d'une machine virtuelle Nutanix.
#
# Ce module crée UNE VM ; c'est le `for_each` du main.tf racine qui en crée plusieurs.
# Le provider Nutanix v2 impose des blocs très imbriqués : les commentaires ci-dessous
# expliquent à quoi correspond chaque niveau.

resource "nutanix_virtual_machine_v2" "this" {
  name        = var.name
  description = var.description

  # CPU total de la VM = num_sockets × num_cores_per_socket
  num_cores_per_socket = var.num_cores_per_socket
  num_sockets          = var.num_sockets
  memory_size_bytes    = var.memory_size_bytes

  # "ON" démarre la VM immédiatement après sa création.
  # Passer une VM existante à "OFF" l'éteint sans la détruire.
  power_state = var.power_state

  # Cluster d'exécution. Dans l'API v2, une entité Nutanix est toujours référencée
  # par son "ext_id", qui est son UUID.
  cluster {
    ext_id = var.cluster_ext_id
  }

  # Disque système, cloné depuis une image existante.
  disks {
    disk_address {
      bus_type = "SCSI"
      index    = 0 # index 0 = disque de boot
    }

    backing_info {
      vm_disk {
        # Taille du disque final. Elle doit être >= à celle de l'image source :
        # le disque peut être agrandi au clonage, jamais réduit.
        disk_size_bytes = var.disk_size_bytes

        # Source du disque : clonage de l'image OS. Sans ce bloc, la VM
        # démarrerait sur un disque vide.
        data_source {
          reference {
            image_reference {
              image_ext_id = var.image_ext_id
            }
          }
        }

        # Conteneur de stockage qui héberge physiquement le disque.
        storage_container {
          ext_id = var.storage_container_ext_id
        }
      }
    }
  }

  # Démarrage en UEFI (et non en BIOS legacy). L'image OS utilisée doit donc
  # elle-même supporter l'UEFI, sinon la VM ne démarrera pas.
  boot_config {
    uefi_boot {
      boot_order = var.boot_order
    }
  }

  # Carte réseau unique, rattachée au subnet fourni.
  nics {
    nic_network_info {
      virtual_ethernet_nic_network_info {
        nic_type = "NORMAL_NIC"

        subnet {
          ext_id = var.subnet_ext_id
        }

        # ACCESS : la VM est dans le VLAN du subnet, sans tag 802.1Q à gérer
        # côté OS. (L'alternative, TRUNK, sert aux VMs qui gèrent plusieurs VLANs.)
        vlan_mode = "ACCESS"
      }
    }
  }
}
