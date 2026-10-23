# Mise en œuvre : architecture locale segmentée (Docker)

> Réalisé pendant l'attente de validation d'un compte cloud, en préparation d'un lab AWS/OCI.
> Mêmes principes ISO/IEC 27001 Annexe A, appliqués ici avec Docker.

## Architecture

```
Internet / Hôte
      │
      │ port 8080
      ▼
┌─────────────────┐        réseau DMZ (lab-dmz-network)
│  Reverse-proxy   │◄───────────────────────────────────
│  (nginx)         │
└────────┬─────────┘
         │  réseau backend (lab-backend-network, internal=true)
         ▼
┌─────────────────┐
│  Backend app     │  ← aucun port publié sur l'hôte
│  (nginx)         │
└─────────────────┘
```

## Contrôles mis en œuvre

| Contrôle | Décision | Implémentation | Vérification |
|---|---|---|---|
| A.8.22 (cloisonnement des réseaux) | Deux réseaux Docker distincts, DMZ et backend, pas de réseau plat | `docker_network.dmz` et `docker_network.backend` dans `main.tf` | `terraform apply` a créé les deux réseaux |
| A.8.22 | Réseau backend en `internal = true` | `docker_network.backend` | Le backend ne résout aucun nom externe (`wget` vers example.com : `bad address`) |
| A.8.20 (sécurité des réseaux) | Un seul service publie un port : le reverse-proxy | Pas de bloc `ports {}` sur `backend_app` | `docker ps` : `8080->80/tcp` pour le proxy, `80/tcp` sans flèche pour le backend |
| A.5.9 (inventaire des actifs) | Nom explicite pour chaque ressource | `lab-dmz-network`, `lab-backend-network`, `lab-reverse-proxy`, `lab-backend-app` | Noms visibles dans `docker ps` |
| A.8.9 (gestion de la configuration) | Configuration du proxy versionnée | `proxy.conf` monté en lecture seule (`read_only = true`) | Non testé |

A.8.22 porte sur le cloisonnement des réseaux (séparation en zones, DMZ). A.8.20 porte sur la sécurité des réseaux en général.

## Mesures effectuées

| Vérification | Résultat |
|---|---|
| `docker ps --format "table {{.Names}}\t{{.Ports}}"` | Proxy : `0.0.0.0:8080->80/tcp`. Backend : `80/tcp` (non publié) |
| `docker exec lab-backend-app wget -T 3 -O /dev/null http://example.com` | `wget: bad address 'example.com'` |
| `curl` de l'hôte vers l'adresse du conteneur backend | `200` |

## Limites

- `internal = true` coupe la résolution de noms externes depuis le backend. L'hôte atteint quand même le backend par son adresse sur le réseau Docker. Un utilisateur connecté à l'hôte peut donc joindre le backend sans passer par le reverse-proxy.
- Non testés : l'accès au backend depuis une autre machine que l'hôte, et l'accès sortant par adresse IP (le test de sortie a utilisé un nom de domaine).
- Le contrôle d'accès à l'hôte (SSH, comptes) fait partie de la protection du backend.

## Ce que ça montre

Le proxy est le seul service qui publie un port. Le backend n'a aucun port publié et ne résout pas de noms externes, mais l'hôte Docker l'atteint directement. Ce cloisonnement reprend l'idée d'une DMZ ; il ne remplace pas le contrôle d'accès à l'hôte. Faire cet exercice avec Docker permet d'appliquer ensuite le même raisonnement à AWS ou OCI.
