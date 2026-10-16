# Alles *innerhalb* des Servers: Datenbanken, Rollen, Rechte.
# Plattformunabhängig, läuft gegen den lokalen Container genauso wie gegen Azure.

terraform {
  required_version = ">= 1.9"

  required_providers {
    postgresql = {
      source  = "cyrilgdn/postgresql"
      version = "~> 1.25"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "postgresql" {
  host      = var.pg_host
  port      = var.pg_port
  username  = var.pg_admin_user
  password  = var.pg_admin_password
  sslmode   = var.pg_sslmode
  superuser = var.pg_superuser
}

resource "postgresql_database" "this" {
  for_each = toset(var.databases)

  name  = each.key
  owner = postgresql_role.group["${each.key}_owner"].name
}
