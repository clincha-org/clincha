# Import blocks adopt objects that already exist in the live MinIO server so
# that `terraform plan` reconciles state without destroying or recreating them.
# The "kubeconfigs" bucket and the read-write "kubeconfig" service account are
# already tracked in state, so they are intentionally not imported here.
#
# Import ID formats (aminueza/minio v3.5.2, all passthrough except attachments):
#   minio_s3_bucket               -> bucket name
#   minio_iam_policy              -> policy name
#   minio_iam_user                -> user name
#   minio_iam_user_policy_attachment -> "<user-name>/<policy-name>"
#   minio_iam_service_account     -> access key

import {
  to = minio_s3_bucket.loki_data
  id = "loki-data"
}

import {
  to = minio_s3_bucket.terraform
  id = "terraform"
}

import {
  to = minio_iam_policy.kubeconfig_ro
  id = "kubeconfig-ro"
}

import {
  to = minio_iam_policy.loki_rw
  id = "loki-rw"
}

import {
  to = minio_iam_policy.terraform_state
  id = "terraform-state"
}

import {
  to = minio_iam_user.loki
  id = "loki"
}

import {
  to = minio_iam_user.terraform
  id = "terraform"
}

import {
  to = minio_iam_user_policy_attachment.loki
  id = "loki/loki-rw"
}

import {
  to = minio_iam_user_policy_attachment.terraform
  id = "terraform/terraform-state"
}

# Read-only "Dave" kubeconfig service account. Access key CJX4INKLQUXY9IKZHC5A
# is the read-only account (s3:ListBucket/GetBucketLocation/GetObject); the
# read-write account ALCRY0NI68NAE0CK8PHZ is already managed as
# minio_iam_service_account.kubeconfig and is therefore not imported.
import {
  to = minio_iam_service_account.kubeconfig_ro
  id = "CJX4INKLQUXY9IKZHC5A"
}
