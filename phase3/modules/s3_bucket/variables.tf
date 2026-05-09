variable "project_name" {
  description = "プロジェクト名"
  type        = string
}

variable "environment" {
  description = "デプロイ環境"
  type        = string
}

variable "bucket_suffix" {
  description = "バケット名の末尾に付加するサフィックス（一意性のため）"
  type        = string
  default     = "001"
}

variable "enable_versioning" {
  description = "S3 バージョニングを有効にするか"
  type        = bool
  default     = false
}
