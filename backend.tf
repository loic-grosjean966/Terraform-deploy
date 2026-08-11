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
#   - Le state contient les valeurs des variables sensibles EN CLAIR (mot de passe Prism
#     Central inclus). À traiter comme un secret.

terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
