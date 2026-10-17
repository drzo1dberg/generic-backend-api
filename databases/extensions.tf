# extensions werden hier gesammelt

# GiST-Operatorenklassen für = auf bigint und text 
resource "postgresql_extension" "btree_gist" {
  name = "btree_gist"
  database = postgresql_database.this["contract"].name
}