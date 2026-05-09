output "bucket_name" {
  description = "作成した S3 バケットの名前"
  value       = aws_s3_bucket.this.bucket
}

output "bucket_arn" {
  description = "作成した S3 バケットの ARN"
  value       = aws_s3_bucket.this.arn
}

output "bucket_id" {
  description = "作成した S3 バケットの ID"
  value       = aws_s3_bucket.this.id
}
