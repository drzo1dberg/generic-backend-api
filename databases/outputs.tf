output "login_passwords" {
  value     = { for k, v in random_password.login : k => v.result }
  sensitive = true
}