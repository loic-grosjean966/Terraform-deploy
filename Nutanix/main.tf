module "vms" {
  for_each = var.vms

  source = "./modules/vm"

  name = each.key
  description = each.value.description

  cluster_ext_id           = var.nutanix_cluster_uuid
  image_ext_id             = var.nutanix_image_uuid
  subnet_ext_id            = var.existing_subnet_ext_id != "" ? var.existing_subnet_ext_id : (var.subnet_ext_id != "" ? var.subnet_ext_id : var.nutanix_subnet_uuid)
  storage_container_ext_id = var.nutanix_storage_container_uuid

  num_cores_per_socket = each.value.num_cores_per_socket
  num_sockets          = each.value.num_sockets
  memory_size_bytes    = each.value.memory_size_bytes
  disk_size_bytes      = each.value.disk_size_bytes
  power_state          = each.value.power_state
  boot_order           = each.value.boot_order
}
