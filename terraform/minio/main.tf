resource "minio_s3_bucket" "kubeconfigs" {
  bucket = "kubeconfigs"
}

resource "minio_iam_policy" "kubeconfig_rw" {
  name   = "kubeconfig-rw"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:*",
        ]
        Resource = [
          "arn:aws:s3:::${minio_s3_bucket.kubeconfigs.bucket}",
          "arn:aws:s3:::${minio_s3_bucket.kubeconfigs.bucket}/*",
        ]
      }
    ]
  })
}

resource "minio_iam_service_account" "kubeconfig" {
  target_user = var.minio_user
  policy      = minio_iam_policy.kubeconfig_rw.policy
}
