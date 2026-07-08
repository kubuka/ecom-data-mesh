resource "snowflake_database" "ecom_db" {
  name = "ECOM_DB"
}

resource "snowflake_schema" "bronze_schema" {
  database                    = snowflake_database.ecom_db.name
  name                        = "BRONZE"
  data_retention_time_in_days = 1
}

data "aws_caller_identity" "current" {
}




#nie potrafilem zrobić z _aws bo te polityki się jakoś psuły
resource "snowflake_storage_integration" "s3_integration" {
  name                      = "S3_BRONZE_INTEGRATION"
  storage_provider          = "S3"
  enabled                   = true
  storage_aws_object_acl    = "bucket-owner-full-control"
  storage_allowed_locations = ["s3://ecom-data-mesh-bronze-layer/"]
  storage_aws_role_arn      = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/snowflake_s3_read_role"
}



#aws role
data "aws_iam_policy_document" "snowflake_trust_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = [snowflake_storage_integration.s3_integration.storage_aws_iam_user_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values = [coalesce(
        snowflake_storage_integration.s3_integration.storage_aws_external_id,
        snowflake_storage_integration.s3_integration.describe_output[0].storage_aws_external_id[0].value,
        "dummy_id"
      )]
    }
  }
}

resource "aws_iam_role" "snowflake_s3_role" {
  name               = "snowflake_s3_read_role"
  assume_role_policy = data.aws_iam_policy_document.snowflake_trust_policy.json
  #depends_on         = [snowflake_storage_integration.s3_integration]
}


data "aws_iam_policy_document" "snowflake_s3_access_policy" {
  statement {
    actions   = ["s3:ListBucket", "s3:GetObject"]
    resources = [aws_s3_bucket.bronze_layer.arn, "${aws_s3_bucket.bronze_layer.arn}/*"]
  }
}

resource "aws_iam_role_policy" "name" {
  name   = "snowflake_s3_read_policy"
  role   = aws_iam_role.snowflake_s3_role.id
  policy = data.aws_iam_policy_document.snowflake_s3_access_policy.json
}

