# Terraform-deploy

Déploiement de VMs Linux sur Nutanix AHV avec OpenTofu / Terraform (provider `nutanix/nutanix` v2.4.2).

## Fonctionnalités

- Création de plusieurs VMs en parallèle via une map (`for_each`)
- Rattachement des VMs à un subnet Nutanix existant
- Configuration UEFI avec ordre de démarrage personnalisable
- Disque système SCSI cloné depuis une image Nutanix

## Structure du projet

```text
Terraform-deploy/
├── modules/
│   └── vm/                  # Module de création d'une VM
│       ├── versions.tf      # Contraintes de providers
│       ├── variables.tf     # Paramètres du module
│       ├── main.tf          # Ressource nutanix_virtual_machine_v2
│       └── outputs.tf       # Valeurs exposées (ext_id, name)
├── backend.tf               # Backend local (terraform.tfstate)
├── versions.tf              # Contraintes + configuration du provider Nutanix
├── variables.tf             # Déclaration des variables
├── main.tf                  # Création des VMs
├── outputs.tf               # Valeurs exposées
└── terraform.tfvars.example
```

## Prérequis

- [OpenTofu](https://opentofu.org/) ou [Terraform](https://www.terraform.io/)
- Accès à un cluster Nutanix AHV (Prism Central)
- Une image OS uploadée dans Nutanix
- Un conteneur de stockage disponible
- Un subnet existant auquel rattacher les VMs

## Configuration

Copier `terraform.tfvars.example` en `terraform.tfvars` et renseigner les vraies valeurs (ce fichier n'est pas versionné) :

```hcl
nutanix_username               = "admin"
nutanix_password               = "mot_de_passe"
nutanix_endpoint               = "192.168.1.100" # IP ou FQDN seul, sans https:// ni port
nutanix_cluster_uuid           = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
nutanix_image_uuid             = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
nutanix_subnet_uuid            = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
nutanix_storage_container_uuid = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

vms = {
  "vm-01" = {
    description          = "Serveur applicatif"
    num_sockets          = 2
    num_cores_per_socket = 2
    memory_size_bytes    = 8589934592  # 8 Go
    disk_size_bytes      = 21474836480 # 20 Go
    power_state          = "ON"
    boot_order           = ["DISK", "NETWORK", "CDROM"]
  }
}
```

## Variables

| Variable | Description | Défaut |
| --- | --- | --- |
| `nutanix_username` | Identifiant Prism Central | — |
| `nutanix_password` | Mot de passe Prism Central | — |
| `nutanix_endpoint` | Adresse IP ou FQDN de Prism Central | — |
| `nutanix_port` | Port de l'API Nutanix | `9440` |
| `nutanix_insecure` | Ignorer la vérification SSL | `true` |
| `nutanix_cluster_uuid` | UUID du cluster Nutanix | — |
| `nutanix_image_uuid` | UUID de l'image OS | — |
| `nutanix_subnet_uuid` | UUID du subnet existant utilisé par les VMs | — |
| `nutanix_storage_container_uuid` | UUID du conteneur de stockage | — |
| `vms` | Map des VMs à créer | `{}` |

Paramètres disponibles par VM dans la map `vms` : `description`, `num_cores_per_socket` (2), `num_sockets` (1), `memory_size_bytes` (8 Go), `disk_size_bytes` (20 Go), `power_state` (`ON`), `boot_order` (`["NETWORK", "DISK", "CDROM"]`).

## Déploiement

```bash
# Initialiser les providers
tofu init

# Vérifier le plan
tofu plan

# Appliquer
tofu apply

# Supprimer les ressources
tofu destroy
```

## Intégration continue

Le workflow [.github/workflows/terraform.yml](.github/workflows/terraform.yml) vérifie le formatage (`tofu fmt -check`) et la validité du code (`tofu validate`) à chaque push et pull request. L'étape `plan` ne s'exécute que si les secrets Nutanix sont configurés sur le dépôt, et nécessite un accès réseau à Prism Central.
