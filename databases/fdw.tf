locals {
    # wer liest über die db: der owner und die zwei app logins
    fdw_kunden_users = toset(["versicherung_owner", "backend", "analyst"])
}

# postgresql_server und postgresql_database haben kein database arg und landen in der db des providers, darum eine zweite instanz für versicherung
provider "postgresql" {
    alias = "versicherung"
    host      = var.pg_host
    port      = var.pg_port
    username  = var.pg_admin_user
    password  = var.pg_admin_password
    sslmode   = var.pg_sslmode
    superuser = var.pg_superuser
    database = postgresql_database.this["versicherung"].name
}

resource "postgresql_extension" "postgres_fdw" {
    name = "postgres_fdw"
    database = postgresql_database.this["versicherung"].name
}

resource "postgresql_server" "kunden" {
    provider = postgresql.versicherung
    server_name = "kunden_srv"
    fdw_name = postgresql_extension.postgres_fdw.name
    options = {
        host = "localhost"
        port = "5432"
        dbname = postgresql_database.this["kunden"].name
    }
}

resource "postgresql_grant" "kunden_srv_usage" {
    database = postgresql_database.this["versicherung"].name
    role     = postgresql_role.group["versicherung_owner"].name
    object_type = "foreign_server"
    objects     = [postgresql_server.kunden.server_name]
    privileges  = ["USAGE"]
}

resource "postgresql_user_mapping" "kunden" {
    for_each = local.fdw_kunden_users

    provider = postgresql.versicherung
    server_name = postgresql_server.kunden.server_name
    user_name = each.key
    options = {
        user = postgresql_role.login["fdw_kunden"].name
        password = random_password.login["fdw_kunden"].result
    }

    depends_on = [postgresql_role.group, postgresql_role.login]
}