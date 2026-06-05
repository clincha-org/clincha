# Buckets ---------------------------------------------------------------------

resource "minio_s3_bucket" "kubeconfigs" {
  bucket = "kubeconfigs"
}

resource "minio_s3_bucket" "loki_data" {
  bucket = "loki-data"
}

# This is the bucket backing the Terraform S3 state backend (providers.tf).
# It is managed here so it is not orphaned, but must never be destroyed.
resource "minio_s3_bucket" "terraform" {
  bucket = "terraform"

  lifecycle {
    prevent_destroy = true
  }
}

# Policies --------------------------------------------------------------------

resource "minio_iam_policy" "kubeconfig_rw" {
  name = "kubeconfig-rw"
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

resource "minio_iam_policy" "kubeconfig_ro" {
  name = "kubeconfig-ro"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
        ]
        Resource = [
          "arn:aws:s3:::${minio_s3_bucket.kubeconfigs.bucket}",
          "arn:aws:s3:::${minio_s3_bucket.kubeconfigs.bucket}/*",
        ]
      }
    ]
  })
}

resource "minio_iam_policy" "loki_rw" {
  name = "loki-rw"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetBucketLocation",
          "s3:ListBucket",
        ]
        Resource = [
          "arn:aws:s3:::${minio_s3_bucket.loki_data.bucket}",
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:DeleteObject",
          "s3:GetObject",
          "s3:PutObject",
        ]
        Resource = [
          "arn:aws:s3:::${minio_s3_bucket.loki_data.bucket}/*",
        ]
      }
    ]
  })
}

resource "minio_iam_policy" "terraform_state" {
  name = "terraform-state"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        # Action order mirrors the live policy to avoid a cosmetic diff.
        Action = [
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
        ]
        Resource = [
          "arn:aws:s3:::${minio_s3_bucket.terraform.bucket}",
          "arn:aws:s3:::${minio_s3_bucket.terraform.bucket}/*",
        ]
      }
    ]
  })
}

# Users -----------------------------------------------------------------------

# Existing user secrets cannot be read back from MinIO. The secret is supplied
# out-of-band via TF_VAR_* and ignored after import so it is never rotated.
variable "loki_secret" {
  type      = string
  sensitive = true
}

variable "terraform_user_secret" {
  type      = string
  sensitive = true
}

resource "minio_iam_user" "loki" {
  name   = "loki"
  secret = var.loki_secret

  lifecycle {
    ignore_changes = [secret]
  }
}

resource "minio_iam_user" "terraform" {
  name   = "terraform"
  secret = var.terraform_user_secret

  lifecycle {
    ignore_changes = [secret]
  }
}

resource "minio_iam_user_policy_attachment" "loki" {
  user_name   = minio_iam_user.loki.name
  policy_name = minio_iam_policy.loki_rw.name
}

resource "minio_iam_user_policy_attachment" "terraform" {
  user_name   = minio_iam_user.terraform.name
  policy_name = minio_iam_policy.terraform_state.name
}

# Service accounts ------------------------------------------------------------

# Read-write kubeconfig service account on the clincha parent user.
resource "minio_iam_service_account" "kubeconfig" {
  target_user = var.minio_user
  policy      = minio_iam_policy.kubeconfig_rw.policy
}

# Read-only ("Dave") kubeconfig service account on the clincha parent user.
resource "minio_iam_service_account" "kubeconfig_ro" {
  target_user = var.minio_user
  policy      = minio_iam_policy.kubeconfig_ro.policy
}
