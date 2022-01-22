variable "project" {
  description = "Google Cloud Platform Project ID"
  default     = "complete-app-324417"
  type        = string
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "service_name" {
  type        = string
  default     = "redisapp"
  description = "Cloud Run service name."
}

variable "container_img" {
  type    = string
  default = "us-central1-docker.pkg.dev/complete-app-324417/cloud-run-source-deploy/redisperf:latest"
}

variable "redis_addr" {
  type        = string
  default     = "redis-13716.c279.us-central1-1.gce.cloud.redislabs.com:13716"
  description = "Redis instance address."
}

variable "cpus" {
  type        = number
  default     = 1
  description = "Number of CPUs per container."
}

variable "memory" {
  type        = number
  default     = 128
  description = "Memory (in Mi) to allocate to container."
}

variable "min_instances" {
  type        = number
  default     = 0
  description = "Minimum number of container instances."
}

variable "max_instances" {
  type        = number
  default     = 2
  description = "Maximum number of container instances."
}
