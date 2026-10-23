# gcp-pubsub-to-bq

Streams Pub/Sub messages into BigQuery through a small Cloud Run service. Pub/Sub pushes each message to the service, which writes it as a row to a BigQuery table.

This repo has the service code and the per-environment Terraform. The infrastructure itself comes from my [pubsub-bq-pipeline](https://registry.terraform.io/modules/amrutp24/pubsub-bq-pipeline/google/latest) module ([source](https://github.com/amrutp24/terraform-google-pubsub-bq-pipeline)).

Written up in [Streaming Events into BigQuery with Pub/Sub, Cloud Run, and Terraform](https://amruteng.medium.com/streaming-events-into-bigquery-with-pub-sub-cloud-run-and-terraform-c1df98417e5b).

## The service

`app/main.py` is a Flask app run by gunicorn.

- `POST /` takes a Pub/Sub push request and inserts one row into BigQuery with `message_id`, `publish_time`, `data` (the decoded message body) and `attributes` (as JSON). It returns 400 for a malformed request and 500 if the insert fails, so Pub/Sub retries.
- `GET /health` returns `OK`.

It reads `BQ_PROJECT`, `BQ_DATASET` and `BQ_TABLE` from the environment; the module sets them on the Cloud Run service.

The Cloud Run service's ingress is set to internal and load balancer traffic only, so it isn't reachable from the public internet. Pub/Sub authenticates each push with an OIDC token for a dedicated service account.

## Layout

```
.
├── app/                        # the Cloud Run service and its Dockerfile
└── terraform/
    ├── environments/
    │   ├── dev/                # uses the registry module (~> 1.2.0)
    │   ├── test/               # uses modules/pubsub_bq_pipeline
    │   └── prod/               # uses modules/pubsub_bq_pipeline
    └── modules/
        └── pubsub_bq_pipeline/ # older local copy of the module
```

dev is on the published module, which adds a dead-letter topic, an optional email alert when messages land there, and dataset-level rather than project-level BigQuery permissions. test and prod still use the older local copy. `dev/moved.tf` maps the resources dev had before it moved to the module, so that switch didn't recreate anything.

The `.tf` files directly under `terraform/` are an earlier starting skeleton and don't create anything; run Terraform from an environment folder.

## Deploy

Enable the APIs once per project:

```bash
gcloud services enable run.googleapis.com artifactregistry.googleapis.com \
  bigquery.googleapis.com pubsub.googleapis.com --project=YOUR_PROJECT
```

Add `monitoring.googleapis.com` if you set `alert_email` in dev.

Each environment keeps state in a GCS bucket you pass at `init`. Copy `terraform.tfvars.example` to `terraform.tfvars` and fill it in (it's gitignored).

The module creates the Artifact Registry repository, but Cloud Run can't start until an image is in it, so the first deploy is three steps:

```bash
cd terraform/environments/dev
terraform init -backend-config="bucket=YOUR_TF_STATE_BUCKET"

# 1. Create the Artifact Registry repository
terraform apply -target=module.pipeline.google_artifact_registry_repository.repo

# 2. Build and push the image
REGION=us-central1
PROJECT=YOUR_PROJECT
IMAGE="$REGION-docker.pkg.dev/$PROJECT/pubsub-to-bq/app:latest"
gcloud auth configure-docker "$REGION-docker.pkg.dev"
docker build -t "$IMAGE" ../../../app
docker push "$IMAGE"

# 3. Everything else
terraform apply
```

After that, `terraform apply` is enough for infrastructure changes. For code changes, push a new image and deploy a new Cloud Run revision.

## Trying it

```bash
gcloud pubsub topics publish test-topic --project=YOUR_PROJECT \
  --message='{"event": "signup", "user": 42}'

bq query --use_legacy_sql=false \
  'SELECT message_id, publish_time, data FROM pubsub_events.events ORDER BY publish_time DESC LIMIT 5'
```

prod's topic is `prod-topic`.

## Cost

Cloud Run scales to zero, and Pub/Sub and BigQuery are billed per use, so an idle pipeline costs close to nothing. At volume, BigQuery streaming inserts are the main cost.
