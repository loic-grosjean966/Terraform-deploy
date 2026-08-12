# Terraform-deploy

Déploiement de VMs Linux sur Nutanix AHV avec OpenTofu / Terraform (provider `nutanix/nutanix` v2.4.2).

Le module utilise la ressource `nutanix_virtual_machine` (API v3) plutôt que
`nutanix_virtual_machine_v2` (API v4) : cette dernière fait échouer systématiquement la
création côté serveur sur ce cluster ("Failed to perform the operation due to an internal
error"), alors que Prism Central — qui s'appuie sur l'API v3 — crée les mêmes VMs sans
problème.

## Fonctionnalités

- Création de plusieurs VMs en parallèle via une map (`for_each`)
- Rattachement des VMs à un subnet Nutanix existant
- Personnalisation au premier démarrage via cloud-init : hostname, compte utilisateur et clés SSH
- Démarrage UEFI, disque système cloné depuis une image Nutanix

## Structure du projet

```text
Terraform-deploy/
├── modules/
│   └── vm/                       # Module de création d'une VM
│       ├── versions.tf           # Contraintes de providers
│       ├── variables.tf          # Paramètres du module
│       ├── main.tf               # Ressource nutanix_virtual_machine (API v3)
│       ├── outputs.tf            # Valeurs exposées (ext_id, name)
│       └── templates/
│           └── user-data.yaml.tftpl   # Gabarit cloud-init (user-data)
├── backend.tf                    # Backend local (terraform.tfstate)
├── versions.tf                   # Contraintes + configuration du provider Nutanix
├── variables.tf                  # Déclaration des variables
├── main.tf                       # Création des VMs
├── outputs.tf                    # Valeurs exposées
└── terraform.tfvars.example
```

## Prérequis

- [OpenTofu](https://opentofu.org/) ou [Terraform](https://www.terraform.io/)
- Accès à un cluster Nutanix AHV (Prism Central)
- Un subnet existant auquel rattacher les VMs
- Un conteneur de stockage sur le cluster (le disque des VMs y est placé automatiquement,
  dans le même conteneur que l'image source — non configurable, voir plus bas)
- Une image OS uploadée dans Nutanix, qui doit :
  - supporter le **démarrage UEFI** (le module force `uefi_boot`)
  - embarquer **cloud-init** — c'est lui qui applique la personnalisation. Les images
    cloud officielles (Ubuntu `-cloudimg`, Debian `genericcloud`, Rocky/Alma `GenericCloud`)
    conviennent ; une image construite à la main depuis une ISO souvent non
- Une paire de clés SSH sur votre poste (`ssh-keygen -t ed25519` si vous n'en avez pas)

## Configuration

Copier `terraform.tfvars.example` en `terraform.tfvars` et renseigner les vraies valeurs (ce fichier n'est pas versionné) :

```hcl
nutanix_username     = "admin"
nutanix_password     = "mot_de_passe"
nutanix_endpoint     = "192.168.1.100" # IP ou FQDN seul, sans https:// ni port
nutanix_cluster_uuid = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
nutanix_image_uuid   = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
nutanix_subnet_uuid  = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"

vms = {
  "vm-01" = {
    description          = "Serveur applicatif"
    num_sockets          = 2
    num_cores_per_socket = 2
    memory_size_bytes    = 8589934592  # 8 Go
    disk_size_bytes      = 21474836480 # 20 Go
    power_state          = "ON"
    ssh_keys             = ["ssh-ed25519 AAAAC3Nza... vous@poste"]
  }
}
```

La clé du dictionnaire (`"vm-01"`) sert à la fois de nom de VM dans Nutanix et de hostname
(en minuscules). La renommer détruit la VM et en recrée une autre.

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
| `vms` | Map des VMs à créer | `{}` |

### Paramètres par VM

Chaque entrée de la map `vms` accepte les champs suivants, tous optionnels :

| Champ | Description | Défaut |
| --- | --- | --- |
| `description` | Description affichée dans Prism Central | `"Machine virtuelle Nutanix"` |
| `num_cores_per_socket` | Cœurs par socket | `2` |
| `num_sockets` | Sockets CPU | `1` |
| `memory_size_bytes` | RAM **en octets** | `8589934592` (8 Go) |
| `disk_size_bytes` | Disque système **en octets**. Ignoré au clonage (voir ci-dessous) | `42949672960` (40 Go) |
| `power_state` | `ON` ou `OFF` | `ON` |
| `ssh_keys` | Clés publiques SSH autorisées | `[]` |
| `cloud_init_user` | Compte créé par cloud-init | `"ubuntu"` |

> `disk_size_bytes` est ignoré par l'API Nutanix lors du clonage : le disque prend d'abord
> la taille de l'image source. Un second `tofu apply`, sans rien changer, détecte l'écart
> et agrandit le disque à la taille demandée.

## Personnalisation cloud-init

Au premier démarrage, chaque VM est configurée à partir du gabarit
[modules/vm/templates/user-data.yaml.tftpl](modules/vm/templates/user-data.yaml.tftpl) :
création du compte `cloud_init_user` avec `sudo` sans mot de passe, installation des clés
publiques déclarées dans `ssh_keys`, et installation de `qemu-guest-agent` (qui permet à
Prism Central de remonter l'IP de la VM). Le hostname est dérivé du nom de la VM.

Trois points à connaître :

- **Sans `ssh_keys`, aucune personnalisation n'est appliquée** (les attributs cloud-init
  restent `null`) : le compte ayant `lock_passwd: true`, une VM sans clé serait de toute
  façon inaccessible. C'est donc le champ à ne pas oublier.
- **Cloud-init ne s'exécute qu'au premier démarrage.** Ajouter une clé dans la configuration
  ne la déploiera pas sur une VM existante, et en retirer une ne révoquera aucun accès. Pour
  gérer les accès dans la durée, il faut modifier `~/.ssh/authorized_keys` sur la VM, ou
  passer par un outil dédié (Ansible, comptes centralisés).
- **`cloud_init_user` doit correspondre à la distribution de l'image** : `ubuntu`, `debian`,
  `rocky`, `almalinux`, `cloud-user`… selon les cas.

Si `package_update: true` est conservé dans le gabarit, les VMs doivent pouvoir joindre les
dépôts de leur distribution au premier démarrage, faute de quoi cloud-init perdra plusieurs
minutes sur cette étape (le reste de la configuration s'appliquera quand même).

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

Une fois les VMs créées, récupérez leur IP dans Prism Central, puis :

```bash
ssh <cloud_init_user>@<ip-de-la-vm>
```

Si la connexion est refusée, c'est généralement que cloud-init n'a pas appliqué le
user-data. Le fichier `/var/log/cloud-init-output.log` sur la VM (accessible depuis la
console Prism Central) en donne la raison. Pour inspecter ce qui a réellement été envoyé,
décodez la valeur `user_data` affichée par `tofu plan` :

```powershell
[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String("<valeur base64>"))
```

Le YAML doit s'afficher sur plusieurs lignes. S'il apparaît sur une seule ligne avec des
`\n` littéraux, cloud-init l'ignorera silencieusement.

## Intégration continue

Le workflow [.github/workflows/terraform.yml](.github/workflows/terraform.yml) vérifie le formatage (`tofu fmt -check`) et la validité du code (`tofu validate`) à chaque push et pull request. L'étape `plan` ne s'exécute que si les secrets Nutanix sont configurés sur le dépôt, et nécessite un accès réseau à Prism Central.
