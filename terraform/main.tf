terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
  }
}

provider "docker" {}

# --- Réseau "DMZ" : seule zone exposée à l'extérieur ---
resource "docker_network" "dmz" {
  name = "lab-dmz-network"
}

# --- Réseau "Backend" : isolé, jamais exposé directement ---
resource "docker_network" "backend" {
  name = "lab-backend-network"
  internal = true # aucune sortie internet ni accès direct depuis l'hôte
}

# --- Image nginx (réutilisée pour le reverse-proxy et le backend) ---
resource "docker_image" "nginx" {
  name         = "nginx:alpine"
  keep_locally = true
}

# --- Backend : le "vrai" service, jamais exposé directement ---
resource "docker_container" "backend_app" {
  name  = "lab-backend-app"
  image = docker_image.nginx.image_id

  networks_advanced {
    name = docker_network.backend.name
  }

  volumes {
    host_path      = "${path.cwd}/../app"
    container_path = "/usr/share/nginx/html"
    read_only      = true
  }

  # Pas de "ports {}" ici : ce conteneur n'a AUCUN port publié vers l'hôte.
  # C'est la mise en œuvre concrète du principe "deny by default" / A.8.20.
}

# --- Reverse-proxy : seul point d'entrée, membre des deux réseaux ---
resource "docker_container" "proxy" {
  name  = "lab-reverse-proxy"
  image = docker_image.nginx.image_id

  networks_advanced {
    name = docker_network.dmz.name
  }
  networks_advanced {
    name = docker_network.backend.name
  }

  ports {
    internal = 80
    external = 8080
  }

  volumes {
    host_path      = "${path.cwd}/proxy.conf"
    container_path = "/etc/nginx/conf.d/default.conf"
    read_only      = true
  }

  depends_on = [docker_container.backend_app]
}
