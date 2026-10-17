locals {
  # wer liest über die db: der owner und die zwei app logins
  fdw_customer_users = toset(["contract_owner", "backend", "analyst"])
}

# postgresql_server und postgresql_database haben kein database arg und landen in der db des providers, darum eine zweite instanz für contract
provider "postgresql" {
  alias     = "contract"
  host      = var.pg_host
  port      = var.pg_port
  username  = var.pg_admin_user
  password  = var.pg_admin_password
  sslmode   = var.pg_sslmode
  superuser = var.pg_superuser
  database  = postgresql_database.this["contract"].name
}

resource "postgresql_extension" "postgres_fdw" {
  name     = "postgres_fdw"
  database = postgresql_database.this["contract"].name
}

resource "postgresql_server" "customer" {
  provider    = postgresql.contract
  server_name = "customer_srv"
  fdw_name    = postgresql_extension.postgres_fdw.name
  options = {
    host   = "localhost"
    port   = "5432"
    dbname = postgresql_database.this["customer"].name
  }
}

resource "postgresql_grant" "customer_srv_usage" {
  database    = postgresql_database.this["contract"].name
  role        = postgresql_role.group["contract_owner"].name
  object_type = "foreign_server"
  objects     = [postgresql_server.customer.server_name]
  privileges  = ["USAGE"]
}

resource "postgresql_user_mapping" "customer" {
  for_each = local.fdw_customer_users

  provider    = postgresql.contract
  server_name = postgresql_server.customer.server_name
  user_name   = each.key
  options = {
    user     = postgresql_role.login["fdw_customers"].name
    password = random_password.login["fdw_customers"].result
  }

  depends_on = [postgresql_role.group, postgresql_role.login]
}