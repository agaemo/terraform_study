terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region

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

# 同じモジュールを for_each で複数の環境に展開する
module "s3_bucket" {
  source = "./modules/s3_bucket"

  for_each = var.environments

  environment       = each.key
  project_name      = var.project_name
  enable_versioning = each.value.enable_versioning
  bucket_suffix     = each.value.bucket_suffix
}
