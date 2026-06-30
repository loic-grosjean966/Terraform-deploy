# Terraform-deploy

Déploiement de VMs Linux sur Nutanix AHV avec Terraform (provider `nutanix/nutanix` v2.4.2).

## Fonctionnalités

- Création de plusieurs VMs en parallèle via une map (`for_each`)
- Création d'un subnet VLAN dédié
- Sélection du subnet par ordre de priorité (dev → existant → par défaut)
- Configuration UEFI avec ordre de démarrage personnalisable
- Disque système SCSI cloné depuis une image Nutanix

## Structure du projet

```text
Terraform-deploy/
└── Nutanix/
    ├── nutanix_provider.tf   # Configuration du provider Nutanix
    ├── variables.tf          # Variables globales
    ├── main.tf               # Création des VMs
    ├── network.tf            # Création du subnet VLAN
    └── modules/
        ├── vm/               # Module de création d'une VM
        └── network/          # Module de création d'un subnet
```

## Prérequis

- [Terraform](https://www.terraform.io/) ou [OpenTofu](https://opentofu.org/)
- Accès à un cluster Nutanix AHV (Prism Central)
- Une image OS uploadée dans Nutanix
- Un conteneur de stockage disponible

## Configuration

Créer un fichier `terraform.tfvars` dans le dossier `Nutanix/` :

```hcl
nutanix_username                = "admin"
nutanix_password                = "mot_de_passe"
nutanix_endpoint                = "192.168.1.100"
nutanix_cluster_uuid            = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
nutanix_image_uuid              = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
nutanix_subnet_uuid             = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
nutanix_storage_container_uuid  = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

vms = {
  "vm-dev-01" = {
    description          = "Serveur de développement"
    num_sockets          = 2
    num_cores_per_socket = 2
    memory_size_bytes    = 8589934592   # 8 Go
    disk_size_bytes      = 21474836480  # 20 Go
    power_state          = "ON"
    boot_order           = ["DISK", "NETWORK", "CDROM"]
  }
}
```

## Variables principales

| Variable | Description | Défaut |
| --- | --- | --- |
| `nutanix_username` | Identifiant Prism Central | — |
| `nutanix_password` | Mot de passe Prism Central | — |
| `nutanix_endpoint` | Adresse IP ou FQDN de Prism Central | — |
| `nutanix_port` | Port de l'API Nutanix | `9440` |
| `nutanix_insecure` | Ignorer la vérification SSL | `true` |
| `nutanix_cluster_uuid` | UUID du cluster Nutanix | — |
| `nutanix_image_uuid` | UUID de l'image OS | — |
| `nutanix_subnet_uuid` | UUID du subnet par défaut | — |
| `nutanix_storage_container_uuid` | UUID du conteneur de stockage | — |
| `dev_subnet_ext_id` | UUID du subnet Dev (priorité 1) | `""` |
| `existing_subnet_ext_id` | UUID d'un subnet existant (priorité 2) | `""` |
| `vms` | Map des VMs à créer | `{}` |

## Réseau créé

Un subnet VLAN est créé automatiquement :

| Paramètre | Valeur |
| --- | --- |
| Nom | `VLAN-DEVOPS` |
| VLAN ID | `100` |
| Réseau | `192.168.100.0/24` |
| Passerelle | `192.168.100.1` |
| Pool DHCP | `192.168.100.20 – 192.168.100.50` |

## Déploiement

```bash
cd Nutanix/

# Initialiser les providers
terraform init

# Vérifier le plan
terraform plan

# Appliquer
terraform apply

# Supprimer les ressources
terraform destroy
```
