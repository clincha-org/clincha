resource "rustfs_bucket" "terraform" {
  name = "terraform"

  lifecycle {
    prevent_destroy = true
  }
}

resource "rustfs_bucket" "loki_data" {
  name = "loki-data"
}

resource "rustfs_bucket" "kubeconfigs" {
  name = "kubeconfigs"
}

# The nested attribute is spelled "ressource" by the provider schema.
resource "rustfs_policy" "terraform_state" {
  name = "terraform-state"
  statement = [
    {
      effect = "Allow"
      action = [
        "s3:DeleteObject",
        "s3:GetBucketLocation",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:PutObject",
      ]
      ressource = [
        "arn:aws:s3:::${rustfs_bucket.terraform.name}",
        "arn:aws:s3:::${rustfs_bucket.terraform.name}/*",
      ]
    },
  ]
}

resource "rustfs_policy" "loki_rw" {
  name = "loki-rw"
  statement = [
    {
      effect    = "Allow"
      action    = ["s3:GetBucketLocation", "s3:ListBucket"]
      ressource = ["arn:aws:s3:::${rustfs_bucket.loki_data.name}"]
    },
    {
      effect    = "Allow"
      action    = ["s3:PutObject", "s3:DeleteObject", "s3:GetObject"]
      ressource = ["arn:aws:s3:::${rustfs_bucket.loki_data.name}/*"]
    },
  ]
}

resource "rustfs_policy" "kubeconfig_rw" {
  name = "kubeconfig-rw"
  statement = [
    {
      effect = "Allow"
      action = ["s3:*"]
      ressource = [
        "arn:aws:s3:::${rustfs_bucket.kubeconfigs.name}",
        "arn:aws:s3:::${rustfs_bucket.kubeconfigs.name}/*",
      ]
    },
  ]
}

resource "rustfs_policy" "kubeconfig_ro" {
  name = "kubeconfig-ro"
  statement = [
    {
      effect = "Allow"
      action = ["s3:GetBucketLocation", "s3:GetObject", "s3:ListBucket"]
      ressource = [
        "arn:aws:s3:::${rustfs_bucket.kubeconfigs.name}",
        "arn:aws:s3:::${rustfs_bucket.kubeconfigs.name}/*",
      ]
    },
  ]
}

# Plain users rather than service accounts: rustfs_serviceaccount has no policy
# attribute, so a service account inherits its parent's permissions — which for
# an admin parent means these would all be unscoped.
resource "rustfs_user" "terraform" {
  access_key = "terraform"
  secret_key = var.terraform_secret
  policy     = rustfs_policy.terraform_state.name
}

resource "rustfs_user" "loki" {
  access_key = "loki"
  secret_key = var.loki_secret
  policy     = rustfs_policy.loki_rw.name
}

resource "rustfs_user" "kubeconfig_ci" {
  access_key = "kubeconfig-ci"
  secret_key = var.kubeconfig_ci_secret
  policy     = rustfs_policy.kubeconfig_rw.name
}

resource "rustfs_user" "kubeconfig_dave" {
  access_key = "kubeconfig-dave"
  secret_key = var.kubeconfig_dave_secret
  policy     = rustfs_policy.kubeconfig_ro.name
}
