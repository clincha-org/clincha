output "kubeconfig_access_key" {
  value = minio_iam_service_account.kubeconfig.access_key
}

output "kubeconfig_secret_key" {
  value     = minio_iam_service_account.kubeconfig.secret_key
  sensitive = true
}
