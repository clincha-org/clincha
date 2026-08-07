variable "endpoint" {
  type    = string
  default = "http://10.2.2.101:3001"
}

# Separate instance from terraform/uptime-kuma, so a separate account. Vault
# item "uptime kuma (watchdog)".
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
