# intro: Terraform の基本概念

## Terraform とは

Terraform は HashiCorp が開発した **Infrastructure as Code（IaC）ツール**。
人間が読める設定ファイル（HCL）でクラウド・オンプレミスのリソースを定義し、
バージョン管理・再利用・チーム共有できる。

> "Terraform is an infrastructure as code tool that lets you build, change,  
> and version cloud and on-prem resources safely and efficiently."  
> — HashiCorp 公式ドキュメント

## なぜ IaC（Infrastructure as Code）なのか

従来のインフラ管理の問題点：

- GUI から手動でリソースを作成 → 誰がいつ何を変更したか追跡不能
- 「本番と同じ環境」を再現するのが難しい
- チームメンバーが増えると設定がバラバラになる

IaC は「インフラの状態をコードで宣言する」ことでこれを解決する。

## Terraform の動作の仕組み

Terraform は **Provider プラグイン**を通じて各プラットフォームの API を呼び出す。
AWS・Azure・GCP・Kubernetes など数千のプロバイダーに対応している。

```
設定ファイル (.tf)
    ↓
Terraform Core
    ↓ API 呼び出し
Provider プラグイン（AWS / GCP / Azure ...）
    ↓
実インフラ
    ↓
State ファイル（現在の状態を記録）
```

## Write → Plan → Apply ワークフロー

Terraform の操作は一貫してこの3段階で進む：

| ステップ | 概要 |
|---------|------|
| **Write（記述）** | 複数クラウドをまたいでリソースを `.tf` ファイルに定義する |
| **Plan（計画）** | 現状の State と設定の差分を計算し、作成・更新・削除する内容を表示する |
| **Apply（適用）** | 承認後、依存関係を解決しながら正しい順序でリソースを操作する |

```bash
terraform init     # プロバイダープラグインをダウンロード
terraform plan     # 変更内容を事前確認（何も変更しない）
terraform apply    # 実際にリソースを作成・変更
terraform destroy  # 管理しているリソースをすべて削除
```

## 主要な概念

### Provider

Terraform がどのインフラを操作するかを指定するプラグイン。
各プロバイダーが固有のリソースタイプと API ラッパーを提供する。

```hcl
provider "aws" {
  region = "ap-northeast-1"
}
```

AWS、GCP、Azure、Kubernetes など多数のプロバイダーが存在する。

### Resource

実際に作成・管理するインフラの単位。

```hcl
resource "aws_s3_bucket" "example" {
  bucket = "my-bucket"
}
```

- `aws_s3_bucket` → リソースタイプ（プロバイダーが定義）
- `example` → このコード内でのリソース名（参照用）

### State（状態ファイル）

Terraform が「今どんなリソースが存在するか」を追跡するファイル（`terraform.tfstate`）。

> **重要**: State は Terraform の正本（source of truth）。
> 手動でリソースを削除しても State には残るので、必ず `terraform destroy` か `terraform state rm` で整合性を保つ。

### 不変インフラストラクチャ（Immutable Infrastructure）

Terraform は **ミュータブル（変更）ではなくイミュータブル（作り直し）** のアプローチを基本とする。
設定変更時はリソースを直接書き換えるのではなく、新しいリソースを作成して古いものを削除する。

| アプローチ | 変更時の挙動 |
|-----------|-------------|
| ミュータブル（Ansible など） | 既存リソースを直接変更する |
| **イミュータブル（Terraform）** | 新リソースを作成 → 旧リソースを削除 |

これにより「途中で失敗して中途半端な状態になる」リスクを減らせる。

### リソースグラフ（Resource Graph）

`terraform apply` 実行時、Terraform はすべてのリソースの依存関係をグラフとして解析する。
**依存関係のないリソースは並列で作成・変更・削除される**ため、大規模構成でも高速に動作する。

```
VPC（先に作成）
 ├── Subnet A ┐
 └── Subnet B ┘ ← 互いに依存しないので並列作成
```

依存関係は `depends_on` で明示するか、リソース参照（`aws_vpc.main.id` など）から自動推論される。

### Module（モジュール）

再利用可能なリソース群をまとめたもの。
同じ構成を複数環境（dev/stg/prod）で使い回せる。

```hcl
module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"
  # ...
}
```

Terraform Registry に公式・コミュニティ製モジュールが公開されている。

## 概念の相関図

各ブロックがコード上でどう繋がっているかをラベルで示す。  
ここでは理解しやすいよう `main.tf` / `variables.tf` / `outputs.tf` の3ファイル構成で示しているが、これはあくまで一例。1ファイルにまとめても、さらに細かく分割しても動作は変わらない。

```hcl
# ── main.tf ──────────────────────────────────────────────────────
terraform {
  required_providers {
    aws = {                   # (A) "aws" という名前でプロバイダーを登録
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
# terraform init がここを読んでプラグインをダウンロードする

provider "aws" {              # (A) required_providers の "aws" と対応
  region = "ap-northeast-1"  #     リージョン・認証情報などを設定する
}                             #     設定不要なプロバイダーはこのブロックごと省略可

resource "aws_s3_bucket" "example" {   # "aws_" プレフィックスが (A) のプロバイダーに対応
  bucket = var.bucket_name             # (B) → var.変数名 で参照
}                                      # (C) このリソース全体を識別するラベル

module "network" {                     # (D) モジュールを呼び出す
  source      = "./modules/network"    #     ローカルパスまたは Registry の URL を指定
  bucket_name = var.bucket_name        # (B) → モジュールへ変数を渡す
}                                      # (E) このモジュール全体を識別するラベル

# ── variables.tf ─────────────────────────────────────────────────
variable "bucket_name" {      # (B) 変数を定義
  default = "my-bucket"
}

# ── outputs.tf ───────────────────────────────────────────────────
output "bucket_id" {
  value = aws_s3_bucket.example.id     # (C) → リソース種別.名前.属性 で参照
}

output "vpc_id" {
  value = module.network.vpc_id        # (E) → module.モジュール名.出力名 で参照
}
```

| ラベル | 意味 |
|--------|------|
| **(A)** | `required_providers` のキー名と `provider "xxx"` のブロック名が一致することでリンクする |
| **(B)** | `variable "x"` で定義した変数は `var.x` で参照する。モジュールへの引数としても渡せる |
| **(C)** | `resource "型" "名前"` は `型.名前.属性` という形で他のブロックから参照できる |
| **(D)** | `module "名前"` でモジュールを呼び出す。`source` にローカルパスまたは Registry の URL を指定する |
| **(E)** | モジュールの出力値は `module.モジュール名.出力名` で参照できる |

## Terraform を使う主な利点

| 利点 | 内容 |
|------|------|
| **追跡可能性** | State ファイルが実インフラの唯一の情報源として機能 |
| **冪等性** | 何度 apply しても同じ結果になる（宣言的記述） |
| **自動化** | 依存関係を Terraform が自動解決するため手順書不要 |
| **標準化** | モジュールで組織内のベストプラクティスを共有できる |
| **マルチクラウド** | AWS・GCP・Azure を同一ワークフローで管理できる |
| **チーム協業** | VCS 管理 + HCP Terraform でレビュー・承認フローを組める |

## 主なユースケース

### マルチクラウドデプロイ

AWS・Azure・GCP など複数のクラウドを**同一ワークフロー**で管理できる。
クラウド間の依存関係も Terraform が解決するため、ベンダーロックインを避けやすい。

### 並列環境の管理（dev / stg / prod）

同じ `.tf` 構成からモジュールや変数を切り替えるだけで複数環境を再現できる。
不要になった環境は `terraform destroy` で即座に削除でき、コストを抑えられる。

### Kubernetes リソース管理

クラスタ自体のプロビジョニング（EKS・GKE など）と、
Pod・Deployment・Service などの Kubernetes リソース管理を同一ツールで行える。

### アプリケーションインフラのデプロイ・スケーリング

Web サーバー・DB・ロードバランサーなど多層構成のリソースを一括定義できる。
リソースグラフにより依存関係を自動解決しながら並列デプロイされる。

## `.tf` ファイルの基本

### Terraform はファイルをどう読むか

Terraform は **同じディレクトリにある `.tf` ファイルをすべて読み込む**。  
ファイルを複数に分けても、1ファイルにまとめても、動作は同じ。  
サブディレクトリは自動では読まない（モジュールとして明示的に呼ぶ必要がある）。

### 一般的なファイル構成

```
project/
├── main.tf           # terraform{} / provider{} / resource{} / module{} をまとめて書く
├── variables.tf      # 入力変数の定義（variable ブロック）※変数がなければ省略可
├── outputs.tf        # 出力値の定義（output ブロック）    ※出力がなければ省略可
└── terraform.tfvars  # 変数に渡す値（機密情報は .gitignore 対象）※variables.tf がある場合のみ
```

これはあくまで**慣習**であり、Terraform 自体はファイル名を関知しない。

> `versions.tf` や `providers.tf` に分割する構成も存在するが、大規模プロジェクトや公開モジュールで見られるスタイル。
> 通常は `main.tf` にまとめて書けば十分。

### `main.tf` は変更できるか？

できる。`main.tf` という名前に特別な意味はなく、`.tf` 拡張子であれば何でもよい。

リソースが増えてきたら用途別に分割するのが一般的：

```
network.tf    # VPC・Subnet・Security Group
compute.tf    # EC2・ECS・Lambda
database.tf   # RDS・DynamoDB
iam.tf        # IAM Role・Policy
```

1ファイルに全部書いても動くが、可読性・保守性のために分割する。

### `terraform {}` ブロックは1つだけか？

**プロジェクト（ディレクトリ）あたり原則1つ**。  
複数の `.tf` ファイルにまたがって書くことは技術的には可能だが、設定が分散して混乱しやすいため `versions.tf` または `main.tf` にまとめるのが慣習。

複数のプロバイダーを使う場合も `required_providers` に並べて書く：

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}
```

### 各ファイルの役割

**main.tf — 何を作るかを定義する**

`resource` ブロックでリソースを宣言する。  
`${var.name}` のように `variables.tf` の変数を参照できる。

```hcl
resource "aws_s3_bucket" "example" {
  bucket = "${var.project_name}-bucket"
}
```

**variables.tf — 外から値を渡すための入口を定義する** ※変数が不要なら省略可

`variable` ブロックで入力変数を定義する。  
`validation` で許可する値を制約することもできる。

```hcl
variable "environment" {
  type    = string
  default = "dev"

  validation {
    condition     = contains(["dev", "stg", "prod"], var.environment)
    error_message = "dev / stg / prod のいずれかを指定してください。"
  }
}
```

値を渡す方法は主に3つ：

| 方法 | 例 |
|------|----|
| コマンドラインで直接渡す | `terraform apply -var="environment=stg"` |
| `.tfvars` ファイルで渡す | `terraform apply -var-file="prod.tfvars"` |
| 環境変数で渡す | `TF_VAR_environment=stg terraform apply` |

**outputs.tf — apply 後に表示する値を定義する** ※出力が不要なら省略可

`output` ブロックで `terraform apply` 完了後に端末に表示される値を定義する。  
`terraform output` コマンドでいつでも再表示できる。  
モジュール間でリソースの情報を受け渡す仕組みとしても使われる（phase3 以降で登場）。

```hcl
output "bucket_name" {
  description = "作成された S3 バケット名"
  value       = aws_s3_bucket.example.bucket
}
```

---

## 次のステップ

→ [フェーズ1：基本操作（init / plan / apply）](../README.md#フェーズ1基本操作init--plan--apply)
