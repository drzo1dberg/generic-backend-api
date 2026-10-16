variable "pg_host" {
  type = string
}

variable "pg_port" {
  type = number
}

variable "pg_admin_user" {
  type = string
}

variable "pg_admin_password" {
  type      = string
  sensitive = true
}

variable "pg_sslmode" {
  description = "Lokal disable, auf Azure require."
  type        = string
  default     = "disable"
}

variable "pg_superuser" {
  description = "Lokal true. Auf Azure false: der Provider darf dann nichts tun, was Superuser-Rechte braucht."
  type        = bool
  default     = true
}

variable "databases" {
  type    = list(string)
  default = ["kunden", "gehalt", "versicherung"]
}
