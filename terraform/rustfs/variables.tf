variable "terraform_secret" {
  type      = string
  sensitive = true
}

variable "loki_secret" {
  type      = string
  sensitive = true
}

variable "kubeconfig_ci_secret" {
  type      = string
  sensitive = true
}

variable "kubeconfig_dave_secret" {
  type      = string
  sensitive = true
}
