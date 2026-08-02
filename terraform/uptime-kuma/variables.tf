variable "endpoint" {
  type    = string
  default = "https://status.clincha.co.uk"
}

# Uptime Kuma is single-user, so this is both Angus's login and the account
# Terraform authenticates as. Keep it in step with the bootstrap secret.
variable "username" {
  type    = string
  default = "clincha"
}

variable "password" {
  type      = string
  sensitive = true
}

variable "telegram_bot_token" {
  type      = string
  sensitive = true
}

variable "telegram_chat_id" {
  type      = string
  sensitive = true
}
