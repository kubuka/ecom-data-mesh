terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.52.0"
    }
    snowflake = {
      source  = "snowflakedb/snowflake"
      version = "2.18.0"
    }
  }
}

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

provider "snowflake" {
  account_name      = var.snowflake_account_name
  organization_name = var.snowflake_organization_name
  user              = var.snowflake_user
  role              = "ACCOUNTADMIN"
  authenticator     = "SNOWFLAKE_JWT"
  private_key       = file("${path.module}/snowflake_key.p8")

  private_key_passphrase   = var.snowflake_private_key_passphrase
  preview_features_enabled = ["snowflake_storage_integration_resource"]

}

