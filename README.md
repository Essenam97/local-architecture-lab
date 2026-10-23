# Local Architecture Lab : segmentation réseau avec Docker et Terraform

Architecture locale qui sépare un reverse-proxy (réseau DMZ) d'un backend (réseau interne), déployée avec Terraform, sans fournisseur cloud. Réalisée pendant l'attente de validation d'un compte cloud. Un lab AWS/OCI est prévu ensuite.

Les contrôles ISO/IEC 27001 Annexe A mis en œuvre et les résultats mesurés sont dans [`docs/controls-implementation.md`](docs/controls-implementation.md).

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

La page HTML du backend s'affiche, relayée par le reverse-proxy.

## Vérifier le cloisonnement

Trois vérifications, avec les résultats observés sur cette architecture.

Ports publiés :

```bash
docker ps --format "table {{.Names}}\t{{.Ports}}"
```

Résultat observé : le proxy affiche `0.0.0.0:8080->80/tcp`, le backend affiche `80/tcp`. Sans flèche `->`, le port est exposé par l'image mais pas publié sur l'hôte.

Sortie vers internet depuis le backend :

```bash
docker exec lab-backend-app wget -T 3 -O /dev/null http://example.com
```

Résultat observé : `wget: bad address 'example.com'`. Le backend ne résout aucun nom externe.

Accès direct de l'hôte à l'adresse du backend :

```bash
curl -sS -m 3 -o /dev/null -w "%{http_code}\n" http://$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' lab-backend-app)
```

Résultat observé : `200`. L'hôte atteint le backend par son adresse sur le réseau Docker. `internal = true` ne bloque donc pas l'hôte lui-même.

## Voir la page dans un navigateur (optionnel)

1. Dans VirtualBox, ajoutez une règle de redirection de port : `Name: web`, `Host Port: 8080`, `Guest Port: 8080`
2. Ouvrez `http://localhost:8080` dans le navigateur Windows

## Nettoyer

```bash
terraform destroy
```

## Structure

```
local-architecture-lab/
├── terraform/
│   ├── main.tf           # Réseaux et conteneurs (proxy et backend)
│   └── proxy.conf        # Configuration nginx du reverse-proxy
├── app/
│   └── index.html        # Page servie par le backend
└── docs/
    └── controls-implementation.md
```

## Prochaine étape

Appliquer la même séparation à une infrastructure cloud, une fois un compte validé.
