# AWS connection & authentication
variable "aws_access_key" {
  type        = string
  description = "AWS access key"
}

variable "aws_secret_key" {
  type        = string
  description = "AWS secret key"
}

variable "aws_region" {
  type        = string
  description = "AWS region"
}

# Cloudflare authentication
variable "cloudflare_token" {
  type        = string
  description = "Cloudflare authentication token"
}

variable "cloudflare_zone_id" {
  type        = string
  description = "Cloudflare zone id"
}
