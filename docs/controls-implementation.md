# Mise en œuvre — Architecture locale segmentée (Docker)

> Complément local au lab AWS/OCI, réalisé pendant l'attente de validation du compte cloud.
> Mêmes principes de gouvernance ISO/IEC 27001 Annexe A, démontrés ici avec Docker plutôt
> qu'avec un fournisseur cloud — la logique de conception est identique.

## Architecture

## Mise en œuvre des contrôles

| Contrôle | Décision | Implémentation |
|---|---|---|
| A.8.22 — Cloisonnement des réseaux (Segregation of networks) | Segmentation en 2 réseaux Docker distincts (DMZ et backend), jamais un seul réseau plat | `docker_network.dmz` et `docker_network.backend` dans `main.tf` |
| A.8.22 (isolation renforcée) | Le réseau backend est déclaré `internal = true` | Aucune sortie internet ni accès direct hôte→conteneur possible sur ce réseau |
| A.8.20 — Sécurité des réseaux | Point d'entrée unique et principe "deny by default" : le backend n'a aucun port publié vers l'hôte | Pas de bloc `ports {}` sur `docker_container.backend_app`, seul le reverse-proxy publie le port 8080 |
| A.5.9 — Inventaire des actifs | Nommage explicite et cohérent de chaque ressource | `lab-dmz-network`, `lab-backend-network`, `lab-reverse-proxy`, `lab-backend-app` |
| A.8.9 — Gestion de la configuration | Configuration du proxy versionnée, pas modifiée à la main dans le conteneur | `proxy.conf` monté en lecture seule (`read_only = true`) |

Note : A.8.22 porte sur le cloisonnement des réseaux (séparation en zones, DMZ), tandis que
A.8.20 porte sur la sécurité des réseaux en général (contrôle des flux, protection des services).

## Ce que ça démontre

Le seul moyen d'atteindre le backend est de passer par le reverse-proxy — exactement le
principe qui sous-tend une architecture DMZ classique en entreprise (serveur web exposé,
base de données ou service interne jamais directement joignable depuis l'extérieur).

Reproduire ce cloisonnement avec Docker en local, avant de le refaire avec AWS/OCI, permet de
valider la compréhension du concept indépendamment d'un fournisseur cloud précis — la
segmentation réseau est un principe transférable, pas une fonctionnalité propriétaire.
