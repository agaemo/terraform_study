# for_each で作成したモジュールの出力は map 形式で取得できる
output "bucket_names" {
  description = "各環境のバケット名マップ"
  value = {
    for env, mod in module.s3_bucket : env => mod.bucket_name
  }
}

output "bucket_arns" {
  description = "各環境のバケット ARN マップ"
  value = {
    for env, mod in module.s3_bucket : env => mod.bucket_arn
  }
}
