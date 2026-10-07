mock_provider "google" {}

variables {
  project_id                  = "test-project"
  network_self_link           = "projects/test-project/global/networks/test-network"
  subnet_self_link            = "projects/test-project/regions/us-central1/subnetworks/test-subnet"
  agent_service_account_email = "agent@test-project.iam.gserviceaccount.com"
  image                       = "projects/test-project/global/images/test-image"
  buildkite_organization_slug = "test-organization"
  buildkite_agent_token       = "test-token"
  enable_autoscaling          = false
  enable_autohealing          = false
}

run "single_machine_type_by_default" {
  command = plan

  assert {
    condition     = length(google_compute_region_instance_group_manager.buildkite_agents.instance_flexibility_policy) == 0
    error_message = "Without machine_types the group must not use instance flexibility."
  }
}

run "ranked_machine_types" {
  command = plan

  variables {
    machine_type   = "c4d-standard-8"
    machine_types  = ["c4d-standard-8", "c4-standard-8", "c3-standard-8"]
    root_disk_type = "hyperdisk-balanced"
  }

  assert {
    condition     = google_compute_region_instance_group_manager.buildkite_agents.distribution_policy_target_shape == "BALANCED"
    error_message = "Instance flexibility needs a non-EVEN distribution shape."
  }

  assert {
    condition = {
      for s in google_compute_region_instance_group_manager.buildkite_agents.instance_flexibility_policy[0].instance_selections :
      s.name => s.rank
    } == { "c4d-standard-8" = 0, "c4-standard-8" = 1, "c3-standard-8" = 2 }
    error_message = "Each machine type must be its own selection, ranked by list position."
  }

  assert {
    condition     = google_compute_instance_template.buildkite_agent.disk[0].disk_type == "hyperdisk-balanced"
    error_message = "hyperdisk-balanced must reach the boot disk."
  }
}

run "rejects_invalid_machine_type" {
  command = plan

  variables {
    machine_types = ["C4D Standard"]
  }

  expect_failures = [var.machine_types]
}
