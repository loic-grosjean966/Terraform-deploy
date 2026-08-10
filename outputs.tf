output "vms" {
  description = "UUID des machines virtuelles créées, par nom"
  value       = { for name, vm in module.vms : name => vm.ext_id }
}
