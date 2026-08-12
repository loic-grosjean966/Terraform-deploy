# Provider Nutanix : version requise et paramètres de connexion à Prism Central.
#
# La version est volontairement figée (et non "~> 2.4") : le provider Nutanix a introduit
# des ressources "_v2" (API v4) qui remplacent progressivement les anciennes, et changer
# de version peut casser la configuration. Ce projet utilise volontairement les
# ressources "classiques" (API v3, ex. nutanix_virtual_machine) plutôt que "_v2" — voir
# modules/vm/main.tf pour le pourquoi. Pour monter de version : modifier le numéro ici,
# lancer `tofu init -upgrade`, puis vérifier le `tofu plan` avant d'appliquer.

terraform {
  required_providers {
    nutanix = {
      source  = "nutanix/nutanix"
      version = "2.4.2"
    }
  }
}

# Les valeurs viennent de terraform.tfvars (non versionné) — voir terraform.tfvars.example.
provider "nutanix" {
  username = var.nutanix_username
  password = var.nutanix_password

  # VIP du cluster Prism Central, sous forme d'IP ou de FQDN uniquement (pas de
  # "https://" ni de port : le port est passé par l'argument `port`).
  # Ne jamais mettre l'adresse d'une CVM individuelle ni la "data services VIP" :
  # les appels échoueraient lors des opérations de cycle de vie du cluster
  # (upgrade AOS, etc.).
  endpoint = var.nutanix_endpoint
  port     = var.nutanix_port
  insecure = var.nutanix_insecure

  # Délai d'attente maximal, en MINUTES, pour la création/modification d'une ressource.
  # La création d'une VM avec clonage d'image peut être longue : augmenter si vous
  # rencontrez des erreurs de timeout.
  wait_timeout = 10
}
