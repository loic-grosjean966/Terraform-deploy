# Stockage de l'état Terraform (state).
#
# Backend "local" : le state est écrit dans le fichier terraform.tfstate, à côté de ce
# fichier. Conséquences importantes à connaître :
#
#   - Le state N'EST PAS versionné (voir .gitignore) : il ne vit que sur la machine qui
#     lance `tofu apply`. Si vous perdez ce fichier, OpenTofu ne sait plus quelles VMs il
#     gère et tentera de tout recréer. Pensez à le sauvegarder.
#   - À deux personnes sur des postes différents, chacun a son propre state : les
#     déploiements se marcheraient dessus. Pour travailler à plusieurs, passer à un
#     backend distant (S3, Azure Storage, PostgreSQL...), qui gère aussi le verrouillage.
#   - Le state est stocké en clair, sans chiffrement. Il ne contient pas les identifiants
#     Prism Central (la configuration d'un provider n'est pas persistée), mais il décrit
#     l'intégralité de l'infrastructure gérée : à traiter comme une donnée sensible.
#   - Attention en revanche aux fichiers de plan sauvegardés (`tofu plan -out=tfplan`) :
#     ceux-là contiennent bien les valeurs des variables, mot de passe compris.

terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
