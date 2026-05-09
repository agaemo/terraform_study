terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}

# テキストファイルを作成するリソース
resource "local_file" "hello" {
  filename = "${path.module}/outputs/hello.txt"
  content  = "Hello, ${var.name}! Terraform で作成されたファイルです。\n作成日時: ${timestamp()}\n"
}

# JSON 形式の設定ファイルを作成するリソース
resource "local_file" "config" {
  filename = "${path.module}/outputs/config.json"
  content = jsonencode({
    environment = var.environment
    project     = var.project_name
    version     = var.app_version
    features    = var.features
  })
}
