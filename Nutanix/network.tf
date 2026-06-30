module "network" {
  source = "./modules/network"

  name               = "VLAN-DEVOPS"
  description        = "Subnet de devops"
  subnet_type        = "VLAN"
  network_id         = 100
  cluster_reference  = var.nutanix_cluster_uuid
  ipv4_network       = "192.168.100.0"
  ipv4_prefix_length = 24
  default_gateway_ip = "192.168.100.1"
  pool_start_ip      = "192.168.100.20"
  pool_end_ip        = "192.168.100.50"
}
