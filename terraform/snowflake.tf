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

#tworzy tutaj swój arn potrzebny do policy (krok 1)
resource "snowflake_storage_integration" "s3_integration" {
  name                      = "S3_BRONZE_INTEGRATION"
  storage_provider          = "S3"
  enabled                   = true
  storage_aws_object_acl    = "bucket-owner-full-control"
  storage_allowed_locations = ["s3://ecom-data-mesh-bronze-layer/"]
  storage_aws_role_arn      = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/snowflake_s3_read_role"
  #załoenie z góry ze tutaj bedzie ta rola, dzięki temu wszystko działa
  #rozwiązanie na circural dependency
}
resource "snowflake_external_volume" "gold_iceberg_volume" {
  name = "GOLD_ICEBERG_VOLUME"
  storage_location {
    storage_location_name = "GOLD_S3_LOCATION"
    storage_provider      = "S3"
    storage_aws_role_arn  = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/snowflake_s3_read_role"
    storage_base_url      = "s3://ecom-data-mesh-gold-layer/"
  }
}



#aws role
# wstrzukuje dane z kroku 1
data "aws_iam_policy_document" "snowflake_trust_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = [snowflake_storage_integration.s3_integration.storage_aws_iam_user_arn, snowflake_external_volume.gold_iceberg_volume.describe_output[0].storage_locations[0].s3_storage_location[0].storage_aws_iam_user_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values = [coalesce(
        snowflake_storage_integration.s3_integration.storage_aws_external_id,
        snowflake_storage_integration.s3_integration.describe_output[0].storage_aws_external_id[0].value,
        "dummy_id"), coalesce(
        snowflake_external_volume.gold_iceberg_volume.describe_output[0].storage_locations[0].s3_storage_location[0].storage_aws_external_id,
        "dummy_id_2")
      ]
    }
  }
}
#tworzy juz faktyczną role pod adresem arn z kroku 1 
resource "aws_iam_role" "snowflake_s3_role" {
  name               = "snowflake_s3_read_role"
  assume_role_policy = data.aws_iam_policy_document.snowflake_trust_policy.json
  #depends_on         = [snowflake_storage_integration.s3_integration]
}


data "aws_iam_policy_document" "snowflake_s3_access_policy" {
  statement {
    actions   = ["s3:ListBucket", "s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = [aws_s3_bucket.bronze_layer.arn, "${aws_s3_bucket.bronze_layer.arn}/*", aws_s3_bucket.gold_layer.arn, "${aws_s3_bucket.gold_layer.arn}/*"]
  }
}
#tworzy policy
resource "aws_iam_role_policy" "name" {
  name   = "snowflake_s3_read_policy"
  role   = aws_iam_role.snowflake_s3_role.id
  policy = data.aws_iam_policy_document.snowflake_s3_access_policy.json
}


#file formats

resource "snowflake_file_format" "json_format" {
  name        = "JSON_FORMAT"
  database    = snowflake_database.ecom_db.name
  schema      = snowflake_schema.bronze_schema.name
  format_type = "JSON"
}

resource "snowflake_file_format" "csv_format" {
  name                         = "CSV_FORMAT"
  database                     = snowflake_database.ecom_db.name
  schema                       = snowflake_schema.bronze_schema.name
  format_type                  = "CSV"
  skip_header                  = 1
  field_optionally_enclosed_by = "\""
}

resource "snowflake_file_format" "parquet_format" {
  name        = "PARQUET_FORMAT"
  database    = snowflake_database.ecom_db.name
  schema      = snowflake_schema.bronze_schema.name
  format_type = "PARQUET"
}


#stage

resource "snowflake_stage" "s3_clickstream_stage" {
  name                = "S3_CLICKSTREAM_STAGE"
  database            = snowflake_database.ecom_db.name
  schema              = snowflake_schema.bronze_schema.name
  url                 = "s3://ecom-data-mesh-bronze-layer/clickstream/"
  storage_integration = snowflake_storage_integration.s3_integration.name
  file_format         = "FORMAT_NAME = ${snowflake_database.ecom_db.name}.${snowflake_schema.bronze_schema.name}.${snowflake_file_format.json_format.name}"
}

resource "snowflake_stage" "s3_exchange_stage" {
  name                = "S3_EXCHANGE_STAGE"
  database            = snowflake_database.ecom_db.name
  schema              = snowflake_schema.bronze_schema.name
  url                 = "s3://ecom-data-mesh-bronze-layer/context_api/"
  storage_integration = snowflake_storage_integration.s3_integration.name
  file_format         = "FORMAT_NAME = ${snowflake_database.ecom_db.name}.${snowflake_schema.bronze_schema.name}.${snowflake_file_format.csv_format.name}"
}

resource "snowflake_stage" "s3_core_system_stage" {
  name                = "S3_CORE_SYSTEM_STAGE"
  database            = snowflake_database.ecom_db.name
  schema              = snowflake_schema.bronze_schema.name
  url                 = "s3://ecom-data-mesh-bronze-layer/core_system/"
  storage_integration = snowflake_storage_integration.s3_integration.name
  file_format         = "FORMAT_NAME = ${snowflake_database.ecom_db.name}.${snowflake_schema.bronze_schema.name}.${snowflake_file_format.parquet_format.name}"
}
