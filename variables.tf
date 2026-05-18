variable "app_name" {
  type        = string
  description = "Application name. Used in resource naming."
}
variable "environment" {
  type        = string
  description = "Deployment environment: dev, staging, or prod."
}
variable "region" {
  type        = string
  description = "AWS region."
  default     = "us-east-1"
}
