# Terraform skeleton

This folder contains a minimal Terraform layout with provider and backend templates.

Quick start:

1. Edit `backend.tf` to set your GCS bucket, or run:

```bash
terraform init -backend-config="bucket=MY_GCS_BUCKET" -backend-config="prefix=terraform/state"
```

2. Fill `variables.tf` values via `-var` or a `terraform.tfvars` file.
3. Run `terraform init` and `terraform plan`.
