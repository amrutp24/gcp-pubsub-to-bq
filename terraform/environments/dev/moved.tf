# State migration: flat resources → module.pipeline
# Safe to delete this file after the first terraform apply succeeds.

moved {
  from = google_pubsub_topic.example
  to   = module.pipeline.google_pubsub_topic.topic
}

moved {
  from = google_pubsub_subscription.cloudrun_push
  to   = module.pipeline.google_pubsub_subscription.subscription
}

moved {
  from = google_bigquery_dataset.main
  to   = module.pipeline.google_bigquery_dataset.dataset
}

moved {
  from = google_bigquery_table.events
  to   = module.pipeline.google_bigquery_table.table
}

moved {
  from = google_artifact_registry_repository.app
  to   = module.pipeline.google_artifact_registry_repository.repo
}

moved {
  from = google_service_account.cloudrun_sa
  to   = module.pipeline.google_service_account.cloudrun_sa
}

moved {
  from = google_service_account.pubsub_invoker_sa
  to   = module.pipeline.google_service_account.pubsub_invoker_sa
}

moved {
  from = google_project_iam_member.cloudrun_bq_data_editor
  to   = module.pipeline.google_project_iam_member.cloudrun_bq_data_editor
}

moved {
  from = google_project_iam_member.cloudrun_bq_job_user
  to   = module.pipeline.google_project_iam_member.cloudrun_bq_job_user
}

moved {
  from = google_cloud_run_v2_service.pubsub_to_bq
  to   = module.pipeline.google_cloud_run_v2_service.service
}

moved {
  from = google_cloud_run_v2_service_iam_member.pubsub_invoker
  to   = module.pipeline.google_cloud_run_v2_service_iam_member.pubsub_invoker
}
