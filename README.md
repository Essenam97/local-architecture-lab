# Local Architecture Lab — Segmentation réseau avec Docker + Terraform

Architecture locale démontrant une segmentation réseau (DMZ / backend isolé), déployée
entièrement via Terraform, sans dépendance à un fournisseur cloud. Réalisée en parallèle
du lab AWS/OCI (`iso27001-lead-implementer-lab`), pendant la validation du compte cloud.

Voir [`docs/controls-implementation.md`](docs/controls-implementation.md) pour le détail
de la mise en œuvre des contrôles ISO/IEC 27001 Annexe A appliqués ici.

## Prérequis

- Terraform installé (`terraform -version`)
- Docker installé et démarré (`docker ps` sans erreur)

## Déploiement

Depuis le dossier `terraform/` :

```bash
cd terraform
terraform init
terraform plan
terraform apply
```

Tapez `yes` pour confirmer.

## Vérifier que ça fonctionne

```bash
curl localhost:8080
```

Vous devez voir le HTML de la page (`✅ Backend atteint avec succès`).

**Vérification de l'isolation** — essayez d'atteindre le backend directement (doit échouer) :
```bash
docker exec lab-reverse-proxy curl -s lab-backend-app:80 | head -5
```
Cette commande fonctionne (le proxy peut atteindre le backend, c'est voulu). Mais depuis
l'hôte, il n'existe **aucun port** vers `lab-backend-app` — seul le proxy est joignable.

## Voir la page dans un navigateur (optionnel)

Si vous voulez voir la page dans votre navigateur Windows plutôt qu'en ligne de commande :

1. Dans VirtualBox, ajoutez une deuxième règle de redirection de port (comme pour SSH) :
   `Name: web`, `Host Port: 8080`, `Guest Port: 8080`
2. Ouvrez `http://localhost:8080` dans votre navigateur Windows

## Nettoyer

```bash
terraform destroy
```

## Structure

```
local-architecture-lab/
├── terraform/
│   ├── main.tf           # Réseaux + conteneurs (proxy + backend)
│   └── proxy.conf         # Configuration nginx du reverse-proxy
├── app/
│   └── index.html         # Page servie par le backend
└── docs/
    └── controls-implementation.md
```

## Prochaine étape

Ce lab sera étendu une fois le compte Oracle Cloud validé, pour comparer la même logique
de segmentation appliquée à une infrastructure cloud réelle.
