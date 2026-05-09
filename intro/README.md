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

## Terraform を使う主な利点

| 利点 | 内容 |
|------|------|
| **追跡可能性** | State ファイルが実インフラの唯一の情報源として機能 |
| **冪等性** | 何度 apply しても同じ結果になる（宣言的記述） |
| **自動化** | 依存関係を Terraform が自動解決するため手順書不要 |
| **標準化** | モジュールで組織内のベストプラクティスを共有できる |
| **マルチクラウド** | AWS・GCP・Azure を同一ワークフローで管理できる |
| **チーム協業** | VCS 管理 + HCP Terraform でレビュー・承認フローを組める |

## 次のステップ

→ [phase1](../phase1/README.md): 実際に Terraform を動かしてみる
