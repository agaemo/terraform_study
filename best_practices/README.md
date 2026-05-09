# best_practices: 本番環境の設計指針

## 基本的なワークフロー

```
コード変更 → terraform plan でレビュー → terraform apply → State を確認
```

---

## 1. State 管理

### ローカル State の問題点

`terraform.tfstate` をローカルに置くと：
- チームで共有できない
- Git にコミットするのは危険（機密情報が含まれる）
- 同時編集でコンフリクトが起きる

### Remote State（本番の基本）

```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state"
    key            = "prod/terraform.tfstate"
    region         = "ap-northeast-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"  # 同時実行防止
  }
}
```

> **State は Terraform の正本。手動でリソースを変更すると State とのズレが生じる。**
> ズレを修正するには `terraform import`（既存リソースを State に取り込む）を使う。

---

## 2. 命名規則

一貫した命名規則はチームの認知負荷を下げる。

```hcl
# バケット名: {project}-{env}-{purpose}
resource "aws_s3_bucket" "app_data" {
  bucket = "${var.project}-${var.env}-app-data"
}

# タグは全リソースに統一して付与する
locals {
  common_tags = {
    Project     = var.project
    Environment = var.env
    ManagedBy   = "terraform"
    Owner       = var.team
  }
}
```

---

## 3. 変数とシークレット管理

```hcl
# 機密情報は sensitive = true を付けてログに表示させない
variable "db_password" {
  type      = string
  sensitive = true
}
```

シークレットの保存先（Terraform コードには書かない）：
- AWS Secrets Manager / Parameter Store
- HashiCorp Vault
- CI/CD ツールの環境変数（GitHub Actions Secrets など）

---

## 4. モジュール設計

```
modules/
├── vpc/          # ネットワーク基盤
├── s3_bucket/    # S3 + バージョニング + ライフサイクル
└── ecs_service/  # ECS タスク定義 + サービス
```

設計指針：
- モジュールは「1つの責務」に絞る
- `variable` は「呼び出し側が決めるべきこと」だけを公開する
- モジュール内の命名規則・タグは `locals` でカプセル化する
- 公開モジュール（Terraform Registry）は本番で使う前にバージョンを固定する

```hcl
# バージョンを固定して予期しない変更を防ぐ
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.2"  # latest ではなく固定バージョン
}
```

---

## 5. Terraform Workspace vs ディレクトリ分割

### Workspace（非推奨）

```bash
terraform workspace new stg
terraform workspace select stg
terraform apply
```

問題点：State は分離されるが、コードは共通。
環境差異が大きくなると管理が困難になる。

### ディレクトリ分割（推奨）

```
environments/
├── dev/
│   ├── main.tf
│   └── terraform.tfvars
├── stg/
│   ├── main.tf
│   └── terraform.tfvars
└── prod/
    ├── main.tf
    └── terraform.tfvars
```

各環境が独立した State を持つため、`prod` への誤操作リスクが低い。

---

## 6. CI/CD での Terraform 実行

```yaml
# GitHub Actions の例
- name: Terraform Plan
  run: terraform plan -out=plan.tfplan

- name: Terraform Apply（main ブランチのみ）
  if: github.ref == 'refs/heads/main'
  run: terraform apply plan.tfplan
```

原則：
- `plan` は PR ごとに自動実行してレビュアーが確認できるようにする
- `apply` は main マージ後のみ、または手動承認後に実行する
- CI/CD でのクレデンシャルは OIDC（AssumeRoleWithWebIdentity）を使う

---

## 7. よくある失敗パターン

| 失敗 | 対策 |
|------|------|
| State ファイルを Git にコミット | `.gitignore` に `*.tfstate` を追加 |
| 手動でリソースを削除して State とズレる | `terraform import` で再取り込み |
| `terraform apply` を確認せずに実行 | 必ず `plan` の差分を読んでから実行 |
| モジュールのバージョンを固定しない | `version = "x.y.z"` で固定 |
| prod の State に直接アクセスできる権限 | IAM で `prod` への書き込みを制限 |

---

## Kafka との対比

| Kafka best_practices | Terraform best_practices |
|---------------------|-------------------------|
| 冪等な Consumer 設計 | `terraform apply` は宣言的で冪等 |
| Dead Letter Topic | `terraform plan` で事前に失敗を検出 |
| オフセット管理 | State 管理（Remote State + Lock） |
| スキーマ管理 | モジュールのバージョン固定 |
| Consumer Lag 監視 | `terraform plan` の差分件数を監視 |
