terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# LocalStack への接続設定
provider "aws" {
  region = var.region

  # LocalStack 用のエンドポイント設定
  access_key                  = "test"
  secret_key                  = "test"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    s3  = "http://localhost:4566"
    iam = "http://localhost:4566"
    sts = "http://localhost:4566"
  }
}

# メインの S3 バケット
resource "aws_s3_bucket" "main" {
  bucket = local.bucket_name

  tags = local.common_tags
}

# バケットのバージョニング設定
resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}

# ログ保存用バケット
resource "aws_s3_bucket" "logs" {
  bucket = local.log_bucket_name

  tags = merge(local.common_tags, {
    Purpose = "access-logs"
  })
}
