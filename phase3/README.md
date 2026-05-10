# phase3: モジュール化

共通のインフラパターンをモジュールとして切り出し、複数の環境で再利用する。
「dev 環境と stg 環境で同じ S3 バケット構成を使い回す」ユースケースで学ぶ。

> **モジュールとは**
> 複数の `resource` をひとまとめにした再利用可能な Terraform の部品。
> 呼び出し側は内部実装を知らなくてよく、変数（inputs）と出力値（outputs）だけを意識すれば使える。
> phase1・2 で書いてきたリソース定義を「テンプレート化」するイメージ。

## 学習目標

1. モジュールを自作して共通パターンを切り出す
2. `for_each` で同一モジュールを複数の環境に展開する
3. モジュールの入力（variables）と出力（outputs）の設計を理解する
4. ルートモジュールとチャイルドモジュールの関係を理解する

## 実行手順

Terraform の **Write → Plan → Apply** ワークフローに沿って進める。

### 1. 準備

```bash
# リポジトリルートで LocalStack を起動（Docker が必要）
docker compose up -d

cd phase3/
```

### 2. Write — 設定ファイルを読む

このフェーズでは `.tf` ファイルがあらかじめ用意されている。
ルートモジュールとチャイルドモジュールの2層構造になっている点を確認してから次に進む。

**このフェーズで作るもの**

`apply` を実行すると LocalStack 上に dev・stg 2環境分の S3 バケットが作成される。

| 作成されるリソース | 内容 |
|----------------|------|
| dev 環境の S3 バケット | バージョニング無効、`terraform-study-dev-001` |
| stg 環境の S3 バケット | バージョニング有効、`terraform-study-stg-001` |

同一の `s3_bucket` モジュールを `for_each` で2回展開することで、コードの重複なく2環境を管理する。

| ファイル | 役割 |
|---------|------|
| `main.tf` | モジュールを `for_each` で呼び出すルートモジュール |
| `variables.tf` | 環境マップ（dev/stg の設定をまとめたオブジェクト型変数） |
| `outputs.tf` | 各環境のバケット名・ARN を `for` 式でマップとして出力 |
| `modules/s3_bucket/main.tf` | S3 バケット・バージョニングの実装 |
| `modules/s3_bucket/variables.tf` | モジュールの入力変数 |
| `modules/s3_bucket/outputs.tf` | モジュールの出力値（バケット名・ARN・ID） |

→ 各ファイルの詳細は「[各ファイルの役割](#各ファイルの役割)」を参照

### 3. Plan — 変更内容を確認する

```bash
terraform init  # プロバイダーとモジュールをダウンロード（Plan の前準備）
terraform plan  # dev / stg 両環境のバケットが計画されることを確認
```

`module.s3_bucket["dev"]` / `module.s3_bucket["stg"]` のように、`for_each` のキーがリソース名に含まれる。

### 4. Apply — リソースを作成する

```bash
terraform apply         # → "yes" と入力して確定

# LocalStack 上の両環境のバケットを確認
aws --endpoint-url=http://localhost:4566 s3 ls

# モジュールのリソースは "module." プレフィックスで表示される
terraform state list

# 出力値をマップ形式で確認
terraform output
```

### 5. Write → Plan → Apply を繰り返す

`variables.tf` の `environments` に `prod` を追加して差分を体験する。

```hcl
# variables.tf の default に prod を追加
prod = {
  enable_versioning = true
  bucket_suffix     = "001"
}
```

```bash
terraform plan   # prod 環境のバケットが新たに追加されることを確認
terraform apply
```

### 6. Destroy — 後片付け

```bash
terraform destroy
# LocalStack のリソースなので料金は発生しないが、destroy の習慣をつけておく
```

## ファイル構成

```
phase3/
├── README.md
├── main.tf                        # ルートモジュール（モジュールを for_each で呼び出す）
├── variables.tf                   # 環境マップ（dev/stg の設定）
├── outputs.tf                     # 各環境のバケット情報を for 式でまとめて出力
└── modules/
    └── s3_bucket/                 # 自作チャイルドモジュール
        ├── main.tf                # S3 バケット・バージョニングの実装
        ├── variables.tf           # モジュールの入力変数
        └── outputs.tf             # モジュールの出力値
```

## 各ファイルの役割

### main.tf（ルート）— モジュールを呼び出す

`module` ブロックで自作モジュールを呼び出す。
`for_each` に環境マップを渡すことで、同じモジュールを複数の環境に展開する。

```hcl
module "s3_bucket" {
  source = "./modules/s3_bucket"    # モジュールの場所

  for_each = var.environments       # environments マップのキーごとにインスタンスを作成

  environment       = each.key                        # "dev" / "stg" など
  project_name      = var.project_name
  enable_versioning = each.value.enable_versioning    # 環境ごとの設定を取り出す
  bucket_suffix     = each.value.bucket_suffix
}
```

---

### variables.tf（ルート）— 環境マップを定義する

phase3 から登場する `object` 型と `map` 型の組み合わせ。
環境ごとの設定を1つの変数にまとめて管理する。

```hcl
variable "environments" {
  type = map(object({
    enable_versioning = bool
    bucket_suffix     = string
  }))
  default = {
    dev = { enable_versioning = false, bucket_suffix = "001" }
    stg = { enable_versioning = true,  bucket_suffix = "001" }
  }
}
```

新しい環境を追加したいときは、このマップにエントリを追加するだけでよい。

---

### outputs.tf（ルート）— for 式でモジュール出力をまとめる

`for_each` で作成したモジュールの出力は `module.名前["キー"].属性` で参照できる。
`for` 式でまとめてマップに変換して出力する。

```hcl
output "bucket_names" {
  value = {
    for env, mod in module.s3_bucket : env => mod.bucket_name
  }
}
# 結果例: { "dev" = "terraform-study-dev-001", "stg" = "terraform-study-stg-001" }
```

---

### modules/s3_bucket/main.tf — モジュールの実装

呼び出し側から渡された変数を使って S3 バケットを作成する。
`locals` で命名規則を統一し、呼び出し側に詳細を意識させない。

```hcl
locals {
  bucket_name = "${var.project_name}-${var.environment}-${var.bucket_suffix}"
}

resource "aws_s3_bucket" "this" {
  bucket = local.bucket_name
  tags   = local.common_tags
}
```

---

### modules/s3_bucket/variables.tf — モジュールの入力変数

モジュールが受け取る変数を定義する。`default` を省略した変数は呼び出し側で必ず指定が必要。

```hcl
variable "environment" {
  description = "デプロイ環境"
  type        = string          # default なし → 必須
}

variable "enable_versioning" {
  type    = bool
  default = false               # default あり → 省略可
}
```

---

### modules/s3_bucket/outputs.tf — モジュールの出力値

モジュール内で作成したリソースの属性を呼び出し側に公開する。
ルートモジュールの `outputs.tf` はここで定義した値を参照する。

```hcl
output "bucket_name" {
  value = aws_s3_bucket.this.bucket
}

output "bucket_arn" {
  value = aws_s3_bucket.this.arn
}
```

---

## モジュール設計の考え方

> **「呼び出し側が知るべきことだけを variable にする」**
> - 内部の命名規則・タグ付けなどは `locals` でモジュール内に隠蔽する
> - 呼び出し側に判断させる設定だけを `variable` として公開する

| 概念 | 役割 |
|------|------|
| ルートモジュール | モジュールを組み合わせてインフラ全体を構成する |
| チャイルドモジュール | 単一の責務（S3 バケット1セット）を担う再利用可能な部品 |
| `variable`（モジュール内） | 呼び出し側からカスタマイズ可能な設定値 |
| `output`（モジュール内） | 呼び出し側が利用できるリソースの属性 |

## 確認ポイント

- `terraform state list` でモジュール内のリソースが `module.<name>["<key>"].<type>.<name>` 形式で表示される
- `for_each` でマップを渡すと、キーごとに独立したリソースが作られる
- 環境を追加するときは `variables.tf` のマップにエントリを1行追加するだけでよい
- `terraform output` の結果がマップ形式で環境ごとにまとまっていることを確認する

## 次のステップ

→ [ベストプラクティス](../README.md#ベストプラクティス)
