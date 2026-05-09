# locals は変数から計算した中間値を定義する場所。
# 外部から変更できない点が variables と異なる。
locals {
  # バケット名は命名規則を統一するためここで生成する
  bucket_name     = "${var.project_name}-${var.environment}-main"
  log_bucket_name = "${var.project_name}-${var.environment}-logs"

  # 全リソースに付与する共通タグ
  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
