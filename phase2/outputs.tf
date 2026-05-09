output "main_bucket_name" {
  description = "作成したメインバケットの名前"
  value       = aws_s3_bucket.main.bucket
}

output "main_bucket_arn" {
  description = "作成したメインバケットの ARN"
  value       = aws_s3_bucket.main.arn
}

output "log_bucket_name" {
  description = "作成したログバケットの名前"
  value       = aws_s3_bucket.logs.bucket
}

output "account_id" {
  description = "現在の AWS アカウント ID（data ソースから取得）"
  value       = data.aws_caller_identity.current.account_id
}

output "region" {
  description = "現在のリージョン（data ソースから取得）"
  value       = data.aws_region.current.name
}
