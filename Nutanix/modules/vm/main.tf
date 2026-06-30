resource "nutanix_virtual_machine_v2" "this" {
  name = var.name
  description = var.description

  num_cores_per_socket = var.num_cores_per_socket
  num_sockets          = var.num_sockets
  memory_size_bytes    = var.memory_size_bytes
  power_state          = var.power_state

  cluster {
    ext_id = var.cluster_ext_id
  }

  disks {
    disk_address {
      bus_type = "SCSI"
      index    = 0
    }

    backing_info {
      vm_disk {
        disk_size_bytes = var.disk_size_bytes

        data_source {
          reference {
            image_reference {
              image_ext_id = var.image_ext_id
            }
          }
        }

        storage_container {
          ext_id = var.storage_container_ext_id
        }
      }
    }
  }
 
  boot_config {
    uefi_boot {
      boot_order = var.boot_order
    }
  }

  nics {
    nic_network_info {
      virtual_ethernet_nic_network_info {
        nic_type = "NORMAL_NIC"

        subnet {
          ext_id = var.subnet_ext_id
        }

        vlan_mode = "ACCESS"
      }
    }
  }
}
