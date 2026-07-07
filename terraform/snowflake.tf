resource "snowflake_database" "ecom_db" {
  name = "ECOM_DB"
}

resource "snowflake_schema" "bronze_schema" {
  database                    = snowflake_database.ecom_db.name
  name                        = "BRONZE"
  data_retention_time_in_days = 7
}

resource "snowflake_storage_integration" "s3_integration" {
  name                      = "S3_BRONZE_INTEGRATION"
  storage_provider          = "S3"
  enabled                   = true
  storage_aws_object_acl    = "bucket-owner-full-control"
  storage_allowed_locations = ["s3://ecom-data-mesh-bronze-layer/"]
}


#aws role
resource "aws_iam_role" "snowflake_s3_role" {
  name = "snowflake_s3_read_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = snowflake_storage_integration.s3_integration.storage_aws_iam_user_arn
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = snowflake_storage_integration.s3_integration.storage_aws_external_id
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "snowflake_s3_policy" {
  name = "snowflake_read_policy"
  role = aws_iam_role.snowflake_s3_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject"
        ]
        Resource = [
          aws_s3_bucket.bronze_layer.arn,
          "${aws_s3_bucket.bronze_layer.arn}/*"
        ]
      }
    ]
  })
}

