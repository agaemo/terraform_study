variable "region" {
  description = "AWS リージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "environment" {
  description = "デプロイ環境"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "stg", "prod"], var.environment)
    error_message = "environment は dev / stg / prod のいずれかを指定してください。"
  }
}

variable "project_name" {
  description = "プロジェクト名（バケット名のプレフィックスに使用）"
  type        = string
  default     = "terraform-study"
}

variable "enable_versioning" {
  description = "S3 バージョニングを有効にするか"
  type        = bool
  default     = false
}
