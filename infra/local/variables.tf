variable "name" {
  description = "Name des Containers (und Präfix des Volumes)."
  type        = string
  default     = "pglab"
}

variable "postgres_version" {
  description = "Tag des offiziellen postgres-Images. Auf Azure Flexible Server dieselbe Major-Version wählen."
  type        = string
  default     = "18"
}

variable "admin_user" {
  description = "Bootstrap-Superuser. Auf Azure gibt es keinen echten Superuser, nur azure_pg_admin."
  type        = string
  default     = "pgadmin"
}

variable "host_port" {
  description = "Port auf 127.0.0.1 des Hosts."
  type        = number
  default     = 5432
}
