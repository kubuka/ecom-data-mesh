variable "project_name" {
  type    = string
  default = "ecom-data-mesh"
}

variable "aws_region" {
  type    = string
  default = "eu-central-1"
}

variable "aws_access_key" {
  type      = string
  default   = ""
  sensitive = true
}

variable "aws_secret_key" {
  type      = string
  default   = ""
  sensitive = true
}

variable "snowflake_organization_name" {
  type = string
}

variable "snowflake_account_name" {
  type = string
}

variable "snowflake_user" {
  type = string
}

variable "snowflake_private_key_passphrase" {
  type      = string
  sensitive = true
}
