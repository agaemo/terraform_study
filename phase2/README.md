# phase2: 変数・ローカル値・データソース

LocalStack を使って AWS S3 バケットを作成する。
変数・ローカル値・データソースで設定を柔軟に管理する方法を学ぶ。

> **LocalStack とは**
> AWS のサービスをローカル PC 上でエミュレートするツール。
> 実際の AWS アカウントや料金なしに S3・IAM などの操作を体験できる。
> Docker で起動し、エンドポイントを `http://localhost:4566` に向けるだけで使える。

## 学習目標

1. `locals` で中間値を計算して重複を排除する
2. `data` ソースで既存リソースの情報を参照する
3. `output` で他のモジュールや CLI に値を公開する
4. `terraform.tfvars` で変数値を環境ごとに切り替える

## 実行手順

Terraform の **Write → Plan → Apply** ワークフローに沿って進める。

### 1. 準備

```bash
# リポジトリルートで LocalStack を起動（Docker が必要）
docker compose up -d

cd phase2/
```

### 2. Write — 設定ファイルを読む

このフェーズでは `.tf` ファイルがあらかじめ用意されている。
各ファイルが何を定義しているかを確認してから次に進む。

**このフェーズで作るもの**

`apply` を実行すると LocalStack 上に S3 バケットが2つ作成される。

| 作成されるリソース | 内容 |
|----------------|------|
| `aws_s3_bucket.main` | メインバケット（バージョニング設定あり） |
| `aws_s3_bucket.logs` | アクセスログ保存用バケット |

バケット名は `variables.tf` の変数と `locals.tf` の計算式で自動生成される（例：`terraform-study-dev-main`）。

| ファイル | 役割 |
|---------|------|
| `main.tf` | S3 バケット・バージョニング設定のリソース定義 |
| `variables.tf` | 環境名・プロジェクト名などの入力変数 |
| `locals.tf` | バケット名や共通タグなどの中間値（外部から変更不可） |
| `data.tf` | 既存リソース（アカウント ID・リージョン）の参照 |
| `outputs.tf` | バケット名・ARN などの出力値 |

→ 各ファイルの詳細は「[各ファイルの役割](#各ファイルの役割)」を参照

### 3. Plan — 変更内容を確認する

```bash
terraform init  # プロバイダーをダウンロード（Plan の前準備）
terraform plan  # 作成されるリソースを確認（実際には何も変更しない）
```

`+` が表示されているリソースが新規作成される（`-` 削除・`~` 変更・`-/+` 再作成）。

### 4. Apply — リソースを作成する

```bash
terraform apply         # → "yes" と入力して確定

# LocalStack 上のバケットを確認
aws --endpoint-url=http://localhost:4566 s3 ls

# output の値を確認（data ソースから取得したアカウント ID なども表示される）
terraform output
```

### 5. Write → Plan → Apply を繰り返す

変数を切り替えて差分がどう表示されるかを体験する。

```bash
# stg 環境の設定で差分を確認（バケット名が変わることを確認）
terraform plan -var="environment=stg"

# バージョニングを有効にした場合の差分
terraform plan -var="enable_versioning=true"
```

### 6. Destroy — 後片付け

```bash
# Terraform リソースを削除
terraform destroy

# リポジトリルートに戻って Docker を停止
cd ..

# コンテナ・ボリューム・イメージをまとめて削除
docker compose down -v --rmi all
```

| オプション | 効果 |
|-----------|------|
| `down` | コンテナを停止・削除 |
| `-v` | ボリューム（`localstack_data`）を削除 |
| `--rmi all` | compose で使用したイメージ（`localstack/localstack`）を削除 |

## ファイル構成

```
phase2/
├── README.md
├── main.tf                       # S3 バケット・バージョニング設定のリソース定義
├── variables.tf                  # 入力変数（環境名・プロジェクト名など）
├── locals.tf                     # ローカル値（バケット名・共通タグの計算）
├── data.tf                       # データソース（アカウント ID・リージョンの参照）
├── outputs.tf                    # 出力値（バケット名・ARN など）
└── terraform.tfvars.example      # 変数ファイルのサンプル
```

## 各ファイルの役割

### main.tf — 何を作るかを定義する

S3 バケット本体とバージョニング設定を `resource` ブロックで定義する。
バケット名は直接書かず、`local.bucket_name` を参照することで命名規則を一元管理している。

```hcl
resource "aws_s3_bucket" "main" {
  bucket = local.bucket_name   # locals.tf で計算した名前を使う

  tags = local.common_tags
}

resource "aws_s3_bucket_versioning" "main" {
  bucket = aws_s3_bucket.main.id

  versioning_configuration {
    status = var.enable_versioning ? "Enabled" : "Suspended"
  }
}
```

---

### variables.tf — 外から値を渡すための入口を定義する

```hcl
variable "environment" {
  type    = string
  default = "dev"

  validation {
    condition     = contains(["dev", "stg", "prod"], var.environment)
    error_message = "environment は dev / stg / prod のいずれかを指定してください。"
  }
}

variable "enable_versioning" {
  type    = bool
  default = false
}
```

`validation` で入力値を制約できる。`bool` 型も使えることを確認する。

---

### locals.tf — 内部で使う中間値を定義する

phase2 から登場する新しいブロック。`variable` との違いは**外部から変更できない**点。

```hcl
locals {
  bucket_name     = "${var.project_name}-${var.environment}-main"
  log_bucket_name = "${var.project_name}-${var.environment}-logs"

  common_tags = {
    Project     = var.project_name
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
```

| | `variable` | `local` |
|-|-----------|---------|
| 外部から変更 | できる（`-var` や `.tfvars`） | できない |
| 用途 | 環境・設定値など外から渡す値 | 変数を組み合わせた中間値・命名規則 |
| 参照方法 | `var.名前` | `local.名前` |

---

### data.tf — 既存リソースの情報を参照する

phase2 から登場する新しいブロック。`resource` と違い、Terraform はデータソースのリソースを**作成・削除しない**。

```hcl
data "aws_caller_identity" "current" {}  # AWS アカウント情報を取得
data "aws_region" "current" {}           # 現在のリージョンを取得
```

取得した値は `data.aws_caller_identity.current.account_id` のように参照する。
LocalStack では `account_id` に `"000000000000"` が返る。

---

### outputs.tf — apply 後に表示する値を定義する

```hcl
output "account_id" {
  description = "現在の AWS アカウント ID（data ソースから取得）"
  value       = data.aws_caller_identity.current.account_id
}
```

`data` ソースから取得した値も `output` に出力できる。
`terraform output -json` で出力値を JSON として取得できる。

---

## 確認ポイント

- `locals` と `variables` の使い分けを理解する
  - `variable`: 外部から渡せる入力値（環境・フラグなど）
  - `local`: 設定ファイル内で計算・加工した中間値（外部から変更不可）
- `data` ソースは「既に存在するリソース」を参照するための仕組みで、作成・削除は行わない
- `terraform output -json` で出力値を JSON として取得できる
- `-var` で変数を上書きして `plan` することで、環境ごとの差分を事前に確認できる

## 次のステップ

→ [フェーズ3：モジュール化](../README.md#フェーズ3モジュール化)
