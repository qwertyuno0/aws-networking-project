variable "environment" {
  description = "environment name"
  type        = string
}

variable "alert_email" {
  description = "email addr for sns notification"
  type        = string
  sensitive   = true

}
