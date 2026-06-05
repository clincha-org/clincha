output "kubeconfig_access_key" {
  value = minio_iam_service_account.kubeconfig.access_key
}

output "kubeconfig_secret_key" {
  value     = minio_iam_service_account.kubeconfig.secret_key
  sensitive = true
}

# Read-only ("Dave") kubeconfig service account access key. The secret key is
# not retrievable for an imported service account, so it is not exported here.
output "kubeconfig_ro_access_key" {
  value     = minio_iam_service_account.kubeconfig_ro.access_key
  sensitive = true
}
