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

## 8. リソースの保護と管理外への移行

### 削除・変更を防ぐ（`lifecycle`）

作成後に変更されたくないリソースには `lifecycle` ブロックで制約をかける。

```hcl
resource "aws_s3_bucket" "main" {
  bucket = local.bucket_name

  lifecycle {
    prevent_destroy = true      # terraform destroy や削除を伴う変更をエラーにする
    ignore_changes  = [tags]    # tags の変更を差分として検出しない
  }
}
```

| オプション | 効果 |
|-----------|------|
| `prevent_destroy` | `destroy` や再作成を伴う変更をエラーにして誤操作を防ぐ |
| `ignore_changes` | 指定した属性が変わっても `plan` に差分を出さない |

### Terraform の管理から完全に外す

外部から作成済みのリソースや、今後 Terraform で変更したくないリソースは `data` ソースに切り替える。

```bash
# State からリソースを除外（リソース自体は削除されない）
terraform state rm aws_s3_bucket.main
```

```hcl
# resource を data に書き換える → 参照のみ、作成・変更・削除しない
data "aws_s3_bucket" "main" {
  bucket = "terraform-study-dev-main"
}
```

| やりたいこと | 方法 |
|------------|------|
| 削除だけ防ぎたい | `lifecycle { prevent_destroy = true }` |
| 一部の変更を無視したい | `lifecycle { ignore_changes = [...] }` |
| 完全に管理をやめたい | `terraform state rm` → `data` に書き換え |

---

## Kafka との対比

| Kafka best_practices | Terraform best_practices |
|---------------------|-------------------------|
| 冪等な Consumer 設計 | `terraform apply` は宣言的で冪等 |
| Dead Letter Topic | `terraform plan` で事前に失敗を検出 |
| オフセット管理 | State 管理（Remote State + Lock） |
| スキーマ管理 | モジュールのバージョン固定 |
| Consumer Lag 監視 | `terraform plan` の差分件数を監視 |
