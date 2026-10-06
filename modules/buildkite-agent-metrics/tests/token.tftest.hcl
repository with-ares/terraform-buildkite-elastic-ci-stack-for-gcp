mock_provider "google" {}
mock_provider "null" {}

variables {
  project_id                  = "test-project"
  buildkite_organization_slug = "test-organization"
  service_account_email       = "metrics@test-project.iam.gserviceaccount.com"
}

run "accepts_token" {
  command = plan

  variables {
    buildkite_agent_token = "test-token"
  }
}

run "accepts_token_secret" {
  command = plan

  variables {
    buildkite_agent_token_secret = "projects/test-project/secrets/test-secret/versions/latest"
  }
}

run "rejects_both" {
  command = plan

  variables {
    buildkite_agent_token        = "test-token"
    buildkite_agent_token_secret = "projects/test-project/secrets/test-secret/versions/latest"
  }

  expect_failures = [google_cloudfunctions2_function.metrics_function]
}

run "rejects_neither" {
  command = plan

  expect_failures = [google_cloudfunctions2_function.metrics_function]
}
