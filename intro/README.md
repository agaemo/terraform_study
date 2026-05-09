# intro: Terraform の基本概念

## なぜ IaC（Infrastructure as Code）なのか

従来のインフラ管理の問題点：

- GUI から手動でリソースを作成 → 誰がいつ何を変更したか追跡不能
- 「本番と同じ環境」を再現するのが難しい
- チームメンバーが増えると設定がバラバラになる

IaC は「インフラの状態をコードで宣言する」ことでこれを解決する。

## Terraform の動作モデル

```
コード（.tf ファイル）
    ↓ terraform plan   # 「現状」と「コード」の差分を表示
差分確認
    ↓ terraform apply  # 差分を実際のインフラに適用
インフラ（AWS・GCP・Azure など）
    ↓
State ファイル（現在の状態を記録）
```

## 主要な概念

### Provider

Terraform がどのインフラを操作するかを指定するプラグイン。

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

### Plan / Apply / Destroy サイクル

```bash
terraform init     # プロバイダープラグインをダウンロード
terraform plan     # 変更内容を事前確認（何も変更しない）
terraform apply    # 実際にリソースを作成・変更
terraform destroy  # 管理しているリソースをすべて削除
```

## Kafka との対比

| Kafka | Terraform |
|-------|-----------|
| Broker | Provider |
| Topic | Resource Type |
| Message | リソースの設定値 |
| Consumer の Offset | State ファイル |
| `docker compose up` | `terraform apply` |

## 次のステップ

→ [phase1](../phase1/README.md): 実際に Terraform を動かしてみる
