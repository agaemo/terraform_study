variable "name" {
  description = "挨拶に使う名前"
  type        = string
  default     = "World"
}

variable "environment" {
  description = "デプロイ環境"
  type        = string
  default     = "dev"

  # 許可する値を validation で制約できる
  validation {
    condition     = contains(["dev", "stg", "prod"], var.environment)
    error_message = "environment は dev / stg / prod のいずれかを指定してください。"
  }
}

variable "project_name" {
  description = "プロジェクト名"
  type        = string
  default     = "terraform-study"
}

variable "app_version" {
  description = "アプリケーションバージョン"
  type        = string
  default     = "1.0.0"
}

variable "features" {
  description = "有効にする機能フラグのリスト"
  type        = list(string)
  default     = ["logging", "monitoring"]
}
