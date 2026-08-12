# Valeurs exposées par le module à son appelant (le main.tf racine).

output "ext_id" {
  description = "UUID de la machine virtuelle créée"
  # Généré par Nutanix à la création. Contrairement à la ressource v2, l'API v3
  # l'expose via l'attribut "id" standard, pas "ext_id".
  value = nutanix_virtual_machine.this.id
}

output "name" {
  description = "Nom de la machine virtuelle créée"
  value       = nutanix_virtual_machine.this.name
}
