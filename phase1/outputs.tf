output "hello_file_path" {
  description = "作成されたテキストファイルのパス"
  value       = local_file.hello.filename
}

output "config_file_path" {
  description = "作成された設定ファイルのパス"
  value       = local_file.config.filename
}

output "config_content" {
  description = "設定ファイルの内容（デバッグ用）"
  value       = jsondecode(local_file.config.content)
}
