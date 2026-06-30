resource "nutanix_subnet_v2" "this" {
  name        = var.name
  description = var.description

  subnet_type = var.subnet_type
  network_id  = var.network_id

  cluster_reference = var.cluster_reference

  ip_config {
    ipv4 {
      ip_subnet {
        ip {
          value = var.ipv4_network
        }
        prefix_length = var.ipv4_prefix_length
      }

      default_gateway_ip {
        value = var.default_gateway_ip
      }

      pool_list {
        start_ip {
          value = var.pool_start_ip
        }
        end_ip {
          value = var.pool_end_ip
        }
      }
    }
  }
}
