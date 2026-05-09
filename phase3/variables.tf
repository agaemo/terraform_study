variable "region" {
  description = "AWS リージョン"
  type        = string
  default     = "ap-northeast-1"
}

variable "project_name" {
  description = "プロジェクト名"
  type        = string
  default     = "terraform-study"
}

variable "environments" {
  description = "デプロイする環境とその設定のマップ"
  type = map(object({
    enable_versioning = bool
    bucket_suffix     = string
  }))
  default = {
    dev = {
      enable_versioning = false
      bucket_suffix     = "001"
    }
    stg = {
      enable_versioning = true
      bucket_suffix     = "001"
    }
  }
}
