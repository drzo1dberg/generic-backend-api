# Vertrag zwischen infra/* und databases/: ein Azure-Modul muss genau diese Outputs liefern.

output "host" {
  value = "127.0.0.1"
}

output "port" {
  value = var.host_port
}

output "admin_user" {
  value = var.admin_user
}

output "admin_password" {
  value     = random_password.admin.result
  sensitive = true
}

output "container_name" {
  value = docker_container.postgres.name
}
