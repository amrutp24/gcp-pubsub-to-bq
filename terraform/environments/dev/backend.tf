# Partial backend configuration — bucket is intentionally omitted.
# Pass it at init time:
#   terraform init -backend-config="bucket=YOUR_TF_STATE_BUCKET"
terraform {
  backend "gcs" {
    prefix = "terraform/dev/state"
  }
}
