# data ソースは「既に存在するリソース」を参照するための仕組み。
# resource と違い、Terraform は data ソースのリソースを作成・削除しない。

# 現在の AWS アカウント情報を取得
# （LocalStack では "000000000000" が返る）
data "aws_caller_identity" "current" {}

# 現在のリージョン情報を取得
data "aws_region" "current" {}
