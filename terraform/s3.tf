resource "aws_s3_bucket" "bronze_layer" {
  bucket = "${var.project_name}-bronze-layer"
  tags = {
    Project = var.project_name
    Layer   = "Bronze"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "bronze_layer_encryption" {
  bucket = aws_s3_bucket.bronze_layer.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "bronze_layer_pab" {
  bucket                  = aws_s3_bucket.bronze_layer.id
  block_public_acls       = true #publiczne uprawnienia do plików
  block_public_policy     = true #publiczne uprawnienia do bucketu
  ignore_public_acls      = true #ignorowanie publicznych uprawnień do plików
  restrict_public_buckets = true #odwołanie wszystkich publicznych uprawnień
}

resource "aws_s3_object" "source_data" {
  for_each = toset(["core_system/", "clickstream/", "context_api/"])

  bucket = aws_s3_bucket.bronze_layer.id
  key    = each.value
}

resource "aws_s3_bucket" "gold_layer" {
  bucket = "${var.project_name}-gold-layer"
  tags = {
    Project = var.project_name
    Layer   = "Gold"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "gold_layer_encryption" {
  bucket = aws_s3_bucket.gold_layer.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "gold_layer_pab" {
  bucket                  = aws_s3_bucket.gold_layer.id
  block_public_acls       = true #publiczne uprawnienia do plików
  block_public_policy     = true #publiczne uprawnienia do bucketu
  ignore_public_acls      = true #ignorowanie publicznych uprawnień do plików
  restrict_public_buckets = true #odwołanie wszystkich publicznych uprawnień
}

