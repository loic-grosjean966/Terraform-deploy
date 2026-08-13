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
- Clavier AZERTY sur la console Prism
- Compte de secours optionnel, accessible en console uniquement
- Préparation optionnelle à l'intégration Active Directory (`realmd` / `sssd`)

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
| `break_glass_user` | Nom du compte de secours accessible en console | `"secours"` |
| `break_glass_password_hash` | Hachage SHA-512 de son mot de passe. Vide = pas de compte | `""` |
| `ad_domain` | Domaine AD à préparer. Vide = pas de préparation | `""` |
| `ad_admin_group` | Groupe AD recevant les droits `sudo` | `""` |

Les quatre dernières sont documentées dans la section [Modèle d'accès](#modèle-daccès).

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

- **Sans `ssh_keys`, la VM est inaccessible.** La personnalisation s'applique quand même
  (hostname, clavier, préparation AD), mais le compte créé n'a pas de mot de passe : sans
  clé publique, aucun moyen de s'y connecter — sauf à avoir défini un compte de secours.
- **Cloud-init ne s'exécute qu'au premier démarrage.** Ajouter une clé dans la configuration
  ne la déploiera pas sur une VM existante, et en retirer une ne révoquera aucun accès. Pour
  gérer les accès dans la durée, il faut modifier `~/.ssh/authorized_keys` sur la VM, ou
  passer par un outil dédié (Ansible, comptes centralisés).
- **`cloud_init_user` doit correspondre à la distribution de l'image** : `ubuntu`, `debian`,
  `rocky`, `almalinux`, `cloud-user`… selon les cas.

Si `package_update: true` est conservé dans le gabarit, les VMs doivent pouvoir joindre les
dépôts de leur distribution au premier démarrage, faute de quoi cloud-init perdra plusieurs
minutes sur cette étape (le reste de la configuration s'appliquera quand même).

## Modèle d'accès

Trois voies d'accès coexistent, avec des rôles distincts. Aucune ne remplace les autres.

### 1. Clé SSH — l'accès nominal

Les clés de `ssh_keys` sont déposées sur le compte `cloud_init_user`. C'est le seul accès
réseau : `ssh_pwauth` n'est pas activé, donc l'image conserve son `PasswordAuthentication no`
et aucun mot de passe ne vaut sur le réseau.

Convention recommandée pour le commentaire de la clé : `utilisateur@poste`
(ex. `lgrosjean@poste-windows`). Il répond à « qui, depuis quelle machine », ce qui est la
question qu'on se pose en relisant un `authorized_keys` des mois plus tard. Une clé par
poste permet de révoquer une machine sans casser les autres.

> Le commentaire d'une clé est du texte libre, sans rôle dans l'authentification. Pour le
> corriger sans régénérer la paire : `ssh-keygen -c -C "nouveau@commentaire" -f ~/.ssh/id_ed25519`

### 2. Compte de secours — la porte dérobée physique

Activé en renseignant `break_glass_password_hash`. Le compte n'a pas de clé SSH et le mot
de passe ne fonctionne pas sur le réseau : il n'est utilisable **que depuis la console
Prism**. Il sert à réparer une VM dont la clé ne fonctionne plus, sans passer par GRUB.

```bash
openssl passwd -6    # saisie masquée, n'apparaît pas dans l'historique
```

```hcl
break_glass_password_hash = "$6$..."
```

Le compromis à accepter : ce hachage part dans le spec de la VM, **lisible via l'API v3 par
tout compte ayant un droit de lecture sur Prism Central**, et donc cassable hors-ligne.
Utiliser un mot de passe long et aléatoire, et le faire tourner. `sensitive = true` ne
masque que les sorties de `tofu` — le state contient la valeur en clair.

Alternative sans secret stocké : la console + GRUB (`e` au démarrage, ajouter
`rw init=/bin/bash` à la ligne `linux`, `Ctrl+X`). Plus lente, impose un redémarrage, mais
ne laisse aucun hachage dans l'API. Si les accès Prism Central sont largement distribués,
c'est l'option la plus sûre.

### 3. Active Directory — l'accès des agents

Renseigner `ad_domain` et `ad_admin_group` fait installer `realmd`/`sssd`/`adcli` et
déposer un fichier `sudoers.d` accordant les droits au **groupe** AD. Les arrivées et les
départs se gèrent alors dans l'annuaire, sans jamais toucher à Terraform.

**La jonction reste manuelle**, une fois par VM, après le premier démarrage :

```bash
sudo realm join --user=<compte-de-jonction> LECREUSOT.PRIV
sudo realm permit -g 'GG_Admins_Linux@lecreusot.priv'
```

Elle n'est pas automatisée volontairement : `realm join` exige un identifiant de domaine,
qui n'a rien à faire dans le user-data où il serait lisible via l'API Nutanix.

Vérification : `realm list`, puis `id monagent@lecreusot.priv`.

Par défaut, la connexion impose le nom complet (`monagent@lecreusot.priv`). Pour le nom
court, passer `use_fully_qualified_names = False` dans `/etc/sssd/sssd.conf` et relancer
`sssd`.

**Les deux causes de la quasi-totalité des échecs de jonction :**

| Prérequis | Vérification |
| --- | --- |
| La VM résout les enregistrements SRV du domaine | `resolvectl query --type=SRV _ldap._tcp.dc._msdcs.<domaine>` |
| L'horloge dérive de moins de 5 minutes (Kerberos) | `timedatectl` |

> **Conserver un accès local.** Si le contrôleur de domaine devient injoignable, `sssd`
> n'authentifie plus que les comptes ayant déjà ouvert une session sur cette machine. Ne
> supprimez ni la clé SSH du compte local, ni le compte de secours.

### Limite commune

Ces trois mécanismes sont appliqués par cloud-init, donc **au premier démarrage uniquement**.
Ajouter la clé d'un collègue impose de recréer la VM :

```powershell
tofu apply '-replace=module.vms["nom-de-la-vm"].nutanix_virtual_machine.this'
```

C'est acceptable pour l'amorçage, pas pour la gestion courante des accès — d'où
l'intégration AD, qui déporte cette gestion dans l'annuaire. À défaut, un outil de gestion
de configuration (Ansible) permet de rejouer les comptes et les clés sans reconstruire.

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

## Choix techniques

Décisions non évidentes du code, avec le problème qu'elles résolvent. Les commentaires
dans les fichiers `.tf` renvoient ici plutôt que de répéter ces explications.

### `meta_data` au format OpenStack ConfigDrive, et non NoCloud

C'est le piège le plus coûteux de ce projet. AHV génère une ISO labellisée `config-2`, au
format **OpenStack ConfigDrive v2** (`openstack/latest/meta_data.json`). cloud-init y
attend les clés `uuid` et `hostname`, qu'il recopie vers `instance-id` et `local-hostname`.

Les clés NoCloud (`instance-id`, `local-hostname`), pourtant les plus documentées en ligne,
sont ignorées — et `uuid` étant **obligatoire**, son absence fait lever `BrokenMetadata`.
Le datasource est alors rejeté, cloud-init retombe sur `DataSourceNone`, et **aucune**
personnalisation n'est appliquée : ni hostname, ni compte, ni clé.

Le symptôme est déroutant, parce que tout semble correct par ailleurs : la VM démarre, le
config drive est bien présent dans le spec, le `user_data` décodé est un YAML valide. Seul
le hostname resté à celui de l'image trahit le problème.

`uuidv5("dns", nom)` rend l'UUID déterministe, pour que l'`instance-id` ne change pas d'un
`apply` à l'autre — sinon cloud-init rejouerait ses modules « per instance » à chaque
redéploiement.

### API v3 plutôt que v4

`nutanix_virtual_machine_v2` faisait échouer la création côté serveur (« Failed to perform
the operation due to an internal error », à 100 % de progression), alors que Prism Central
créait les mêmes VMs sans problème. Prism Central s'appuyant sur l'API v3, le module
l'utilise directement. Conséquence : la mémoire et les disques se déclarent en **mébioctets**,
là où l'API v2 attendait des octets.

### Neutralisation des CRLF

Le `replace(..., "\r\n", "\n")` du module protège des retours à la ligne Windows :
cloud-init ignore silencieusement un user-data dont le YAML tient sur une seule ligne avec
des `\n` littéraux.

### Pas de `storage_config`

Au clonage d'une image, Nutanix place le disque dans le conteneur de l'image source. En
forcer un autre fait échouer la création — comportement confirmé sur les API v2 et v3 ainsi
que dans l'assistant de Prism Central.

### `packagekit` dans la liste des paquets AD

Il n'est pas superflu : `realmd` s'en sert pour vérifier ses dépendances, et `realm join`
échoue sans lui avec « Necessary packages are not installed ».

### Erreurs YAML signalées par l'éditeur sur le gabarit

Les messages du type `Plain value cannot start with directive indicator character %` sur
`user-data.yaml.tftpl` sont des faux positifs : le linter YAML bute sur les directives
`%{ if }` et `%{ for }` de `templatefile`. Le fichier n'est pas du YAML, mais un gabarit
qui en produit. Pour contrôler le rendu réel :

```bash
echo 'templatefile("./modules/vm/templates/user-data.yaml.tftpl", { ... })' | tofu console
```

## Intégration continue

Le workflow [.github/workflows/terraform.yml](.github/workflows/terraform.yml) vérifie le formatage (`tofu fmt -check`) et la validité du code (`tofu validate`) à chaque push et pull request. L'étape `plan` ne s'exécute que si les secrets Nutanix sont configurés sur le dépôt, et nécessite un accès réseau à Prism Central.
