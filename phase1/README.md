# phase1: 最初の Terraform 設定

`local` プロバイダーを使い、ローカルにファイルを作成する。
AWS も Docker も不要で、Terraform の基本操作（init/plan/apply/destroy）を体験する。

## 学習目標

1. `terraform init` でプロバイダーをダウンロードする
2. `terraform plan` で変更内容を事前確認する
3. `terraform apply` でリソースを作成する
4. `terraform destroy` でリソースを削除する
5. State ファイルが何を記録しているか確認する

## 実行手順

```bash
# 1. mise に .mise.toml を信頼させる（初回のみ）
mise trust

# 2. Terraform をインストール
mise install

cd phase1/

# 3. プロバイダーをダウンロード
terraform init

# 4. 作成されるリソースを確認（実際には何も変更しない）
terraform plan

# 5. リソースを作成
terraform apply
# → "yes" と入力して確定

# 6. 生成されたファイルを確認
cat outputs/hello.txt
cat outputs/config.json

# 7. State ファイルを確認（Terraform が追跡している状態）
cat terraform.tfstate

# 8. main.tf を変更して再度 plan/apply で差分を体験する

# 9. 後片付け（local プロバイダーはローカルファイルのみなので省略可）
# AWS 等のクラウドリソースでは放置するとコストが発生するため必須の習慣
terraform destroy
```

## ファイル構成

```
phase1/
├── README.md
├── main.tf         # リソース定義（何を作るか）
├── variables.tf    # 入力変数の定義
├── outputs.tf      # 出力値の定義
└── outputs/        # Terraform が生成するファイル（gitignore 対象外）
```

## 各ファイルの役割

### main.tf — 何を作るかを定義する

Terraform の中心となるファイル。2つのブロックで構成されている。

**`terraform {}` ブロック**

```hcl
terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}
```

使用するプロバイダー（Terraform のプラグイン）を宣言する。  
`terraform init` はここを読んで必要なプロバイダーをダウンロードする。  
このフェーズでは AWS ではなく `local`（ローカルファイルを操作するプロバイダー）を使っている。

**`resource` ブロック**

```hcl
resource "local_file" "hello" {
  filename = "${path.module}/outputs/hello.txt"
  content  = "Hello, ${var.name}! ..."
}
```

`resource "リソースの種類" "名前"` という形式で、作成するリソースを定義する。  
`var.name` のように `variables.tf` で定義した変数を参照できる。  
`terraform apply` を実行するとこの定義通りにファイルが作成される。

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
```

`variable` ブロックで入力変数を定義する。`default` を設定しておくと、値を渡さなくても動作する。  
`validation` ブロックで許可する値を制約できる（上の例では `dev` / `stg` / `prod` 以外はエラー）。

変数に値を渡す方法は主に3つ：

| 方法 | 例 |
|------|----|
| コマンドラインで直接渡す | `terraform apply -var="environment=stg"` |
| `.tfvars` ファイルで渡す | `terraform apply -var-file="prod.tfvars"` |
| 環境変数で渡す | `TF_VAR_environment=stg terraform apply` |

---

### outputs.tf — apply 後に表示する値を定義する

```hcl
output "hello_file_path" {
  description = "作成されたテキストファイルのパス"
  value       = local_file.hello.filename
}
```

`terraform apply` の完了後に端末に表示される値を定義する。  
`local_file.hello.filename` のように、リソースの属性を参照して値を取り出せる。  
`terraform output` コマンドでいつでも再表示できる。

outputs は「結果の確認」だけでなく、モジュール間でリソースの情報を受け渡す仕組みとしても使われる（phase3 以降で登場）。

---

## 確認ポイント

- `terraform plan` の `+` / `-` / `~` の意味を理解する
  - `+` 追加、`-` 削除、`~` 変更（in-place）、`-/+` 再作成
- `terraform.tfstate` の中身を見て、State が何を記録しているか確認する
- `main.tf` の `content` を変更して `terraform plan` を実行し、差分が表示されることを確認する

## 次のステップ

→ [フェーズ2：変数・出力・データソース](../README.md#フェーズ2変数出力データソース)
