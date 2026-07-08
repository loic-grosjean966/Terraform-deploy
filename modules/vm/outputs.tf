output "ext_id" {
  description = "UUID de la machine virtuelle créée"
  value       = nutanix_virtual_machine_v2.this.ext_id
}

output "name" {
  description = "Nom de la machine virtuelle créée"
  value       = nutanix_virtual_machine_v2.this.name
}
