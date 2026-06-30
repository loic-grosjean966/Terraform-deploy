// Déclaration de la VM avec le provider Nutanix V2 dans le cadre d'un déploiement DevOps avec Ansible
// Documentation du provider Nutanix V2 : https://registry.terraform.io/providers/nutanix/nutanix/latest/docs
resource "nutanix_virtual_machine_v2" "HDVDEVOPS"{
    name= "HDVDEVOPS"
    description =  "Machine virtuelle sous Linux pour Intranet DevOps"
    // Configuration du vCPU et de la mémoire RAM de la VM
    num_cores_per_socket = 2
    num_sockets = 1
    memory_size_bytes = 8 * pow(1024, 3) # 8 GB
    power_state = "ON"
    cluster {
        ext_id = "1cefd0f5-6d38-4c9b-a07c-bdd2db004224"
    }
    disks{
        disk_address{
            bus_type = "SCSI"
            index = 0
        }
        backing_info{
            vm_disk{
              disk_size_bytes = 20 * pow(1024, 3) # 20 GB
              data_source {
                reference {
                  image_reference {
                    image_ext_id = "59ec786c-4311-4225-affe-68b65c5ebf10"
                  }
                }
              }
              storage_container{
                ext_id = "1cefd0f5-6d38-4c9b-a07c-bdd2db004224"
              }
            }
        }
    }
    boot_config {
      uefi_boot {
        boot_order = ["NETWORK", "DISK", "CDROM"]
      }
    }
    nics {
      network_info {
        nic_type = "NORMAL_NIC"
        subnet {
          ext_id = "1cefd0f5-6d38-4c9b-a07c-bdd2db004224"
        }
        vlan_mode = "ACCESS"
      }
        
    }
}