# Valeurs exposées par le module à son appelant (le main.tf racine).

output "ext_id" {
  description = "UUID de la machine virtuelle créée"
  # Généré par Nutanix à la création : c'est l'identifiant à utiliser pour
  # retrouver la VM dans Prism Central ou via l'API.
  value = nutanix_virtual_machine_v2.this.ext_id
}

output "name" {
  description = "Nom de la machine virtuelle créée"
  value       = nutanix_virtual_machine_v2.this.name
}
