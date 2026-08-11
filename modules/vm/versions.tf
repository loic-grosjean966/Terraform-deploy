# Providers requis par le module.
#
# Volontairement sans contrainte de version : c'est le rôle de la configuration racine
# (../../versions.tf) de figer la version du provider. Un module qui imposerait sa propre
# contrainte risquerait d'entrer en conflit avec celle de la racine.
#
# Aucun bloc `provider` ici non plus : le module hérite de celui configuré à la racine.

terraform {
  required_providers {
    nutanix = {
      source = "nutanix/nutanix"
    }
  }
}
