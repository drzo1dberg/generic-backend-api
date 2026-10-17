locals {
  group_suffixes = ["owner", "rw", "ro"]

  group_roles = toset([
    for p in setproduct(var.databases, local.group_suffixes) :
    "${p[0]}_${p[1]}"
  ])

  login_roles = {
    backend = [for db in var.databases : "${db}_rw"]
    analyst = [for db in var.databases : "${db}_ro"]
    fdw_kunden = ["kunden_ro"]
  }

  connect_grants = {
    for p in setproduct(var.databases, ["rw", "ro"]) :
    "${p[0]}_${p[1]}" => p[0]
  }

  def_prvlgs = {
    rw = {
      table    = ["SELECT", "INSERT", "UPDATE", "DELETE"]
      sequence = ["USAGE", "SELECT"]
    }
    ro = {
      table    = ["SELECT"]
      sequence = ["SELECT"]
    }
  }
  def_grants = {
    for g in flatten([
      for db in var.databases : [
        for kind, obj in local.def_prvlgs : [
          for obj_type, prvlgs in obj : {
            key         = "${db}_${kind}_${obj_type}"
            database    = db
            role        = "${db}_${kind}"
            object_type = obj_type
            privileges  = prvlgs
          }
        ]
      ]
    ]) : g.key => g
  }

}

resource "postgresql_role" "group" {
  for_each = local.group_roles

  name  = each.key
  login = false
}

resource "random_password" "login" {
  for_each = local.login_roles

  length  = 32
  special = false
}

resource "postgresql_role" "login" {
  for_each = local.login_roles

  name     = each.key
  login    = true
  password = random_password.login[each.key].result

  roles = [
   for g in each.value : postgresql_role.group[g].name
  ]
}

resource "postgresql_grant" "revoke_public" {
  for_each = toset(var.databases)

  database    = postgresql_database.this[each.key].name
  role        = "public"
  object_type = "database"
  privileges  = []
}

resource "postgresql_grant" "connect" {
  for_each = local.connect_grants

  database    = postgresql_database.this[each.value].name
  role        = postgresql_role.group[each.key].name
  object_type = "database"
  privileges  = ["CONNECT"]
}

resource "postgresql_default_privileges" "this" {
  for_each = local.def_grants

  database    = postgresql_database.this[each.value.database].name
  owner       = postgresql_role.group["${each.value.database}_owner"].name
  role        = postgresql_role.group[each.value.role].name
  schema      = "public"
  object_type = each.value.object_type
  privileges  = each.value.privileges
}
