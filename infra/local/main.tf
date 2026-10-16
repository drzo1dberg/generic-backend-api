# Lokale "Plattform": ein PostgreSQL-Server als Docker-Container.
# Gegenstück später: infra/azure (azurerm_postgresql_flexible_server) mit denselben Outputs.

terraform {
  required_version = ">= 1.9"

  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "~> 3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "docker" {}

resource "random_password" "admin" {
  length  = 32
  special = false
}

resource "docker_image" "postgres" {
  name         = "postgres:${var.postgres_version}"
  keep_locally = true
}

resource "docker_volume" "pgdata" {
  name = "${var.name}-pgdata"
}

resource "docker_container" "postgres" {
  name  = var.name
  image = docker_image.postgres.image_id

  env = [
    "POSTGRES_USER=${var.admin_user}",
    "POSTGRES_PASSWORD=${random_password.admin.result}",
  ]

  # pg_stat_statements muss vorgeladen werden (auch auf Azure über Serverparameter möglich).
  command = [
    "postgres",
    "-c", "shared_preload_libraries=pg_stat_statements",
    "-c", "log_min_duration_statement=500",
  ]

  ports {
    internal = 5432
    external = var.host_port
    ip       = "127.0.0.1"
  }

  # Ab PostgreSQL 18 liegt PGDATA unter /var/lib/postgresql/<major>/docker.
  volumes {
    volume_name    = docker_volume.pgdata.name
    container_path = "/var/lib/postgresql"
  }

  # -h 127.0.0.1: der temporäre Init-Server lauscht nur auf dem Unix-Socket,
  # so wird der Container erst "healthy", wenn der echte Server läuft.
  healthcheck {
    test         = ["CMD-SHELL", "pg_isready -h 127.0.0.1 -U ${var.admin_user}"]
    interval     = "2s"
    timeout      = "2s"
    retries      = 30
    start_period = "5s"
  }

  wait         = true
  wait_timeout = 120
}
