module "pipeline" {
  source = "../../modules/pubsub_bq_pipeline"

  project    = var.project
  region     = var.region
  topic_name = "test-topic"

  bq_dataset_id = "pubsub_events"
  bq_table_id   = "events"

  image        = "${var.region}-docker.pkg.dev/${var.project}/pubsub-to-bq/app:latest"
  service_name = "pubsub-to-bq"

  labels = {
    purpose     = "testing"
    environment = "test"
  }
}
