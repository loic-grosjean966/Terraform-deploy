output "ext_id" {
  description = "UUID du subnet créé"
  value       = nutanix_subnet_v2.this.ext_id
}

output "name" {
  description = "Nom du subnet créé"
  value       = nutanix_subnet_v2.this.name
}
