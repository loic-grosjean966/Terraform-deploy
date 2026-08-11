# Valeurs affichées après un `tofu apply` (et consultables ensuite avec `tofu output`).

output "vms" {
  description = "UUID des machines virtuelles créées, par nom"

  # Transforme les instances du module en une map lisible : { "NOM-VM" = "uuid", ... }.
  # Utile pour retrouver une VM dans Prism Central ou l'utiliser depuis un autre outil.
  value = { for name, vm in module.vms : name => vm.ext_id }
}
