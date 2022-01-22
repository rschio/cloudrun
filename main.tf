terraform {
  required_providers {
    google = ">= 4.7.0"
  }

  backend "gcs" {
    bucket = "terraform_d"
	prefix = "terraform/state"
  }
}

provider "google" {
  project     = var.project
}

# Enable the Cloud Run API.
resource "google_project_service" "run_api" {
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_service_account" "service_account" {
  account_id   = "terraform-acc"
  display_name = "Terraform"
}

resource "google_secret_manager_secret_iam_member" "secret_access" {
  secret_id  = "REDIS_PASSWORD"
  role       = "roles/secretmanager.secretAccessor"
  member     = "serviceAccount:${google_service_account.service_account.email}"
  depends_on = [google_service_account.service_account]
}

# Create the Cloud Run service.
resource "google_cloud_run_service" "run_service" {
  name     = var.service_name
  location = var.region

  template {
    spec {
      service_account_name = google_service_account.service_account.email
      containers {
        image = var.container_img
        resources {
          limits = {
            cpu    = "${var.cpus * 1000}m"
            memory = "${var.memory}Mi"
          }
        }
        env {
          name  = "REDIS_ADDR"
          value = var.redis_addr
        }
        env {
          name = "REDIS_PASSWORD"
          value_from {
            secret_key_ref {
              name = "REDIS_PASSWORD"
              key  = "latest"
            }
          }
        }
      }
    }
    metadata {
      annotations = {
        "autoscaling.knative.dev/maxScale" = var.max_instances
        "autoscaling.knative.dev/minScale" = var.min_instances
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  # Waits for the Cloud Run API to be enabled.
  depends_on = [google_project_service.run_api, google_service_account.service_account]
}

# Allow unauthenticated users to invoke the service.
resource "google_cloud_run_service_iam_member" "run_all_users" {
  service  = google_cloud_run_service.run_service.name
  location = google_cloud_run_service.run_service.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}

# Display the service URL.
output "service_url" {
  value = google_cloud_run_service.run_service.status[0].url
}
