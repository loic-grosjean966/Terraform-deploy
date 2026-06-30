// Déclaration du provider Nutanix
terraform {
  required_providers {
    nutanix = {
      source = "nutanix/nutanix"
      version = "2.4.2"
    }
  }
}
// Configuration du provider Nutanix
provider "nutanix" {
  username     = var.nutanix_username
  password     = var.nutanix_password
  endpoint     = var.nutanix_endpoint
  port         = var.nutanix_port
  insecure     = var.nutanix_insecure
  wait_timeout = 10
}