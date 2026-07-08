output "network_ext_id" {
  description = "UUID du subnet créé"
  value       = module.network.ext_id
}

output "vms" {
  description = "UUID des machines virtuelles créées, par nom"
  value       = { for name, vm in module.vms : name => vm.ext_id }
}
