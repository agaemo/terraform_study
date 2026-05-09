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
cd phase1/

# 1. Terraform をインストール（mise を使用）
mise install

# 2. プロバイダーをダウンロード
terraform init

# 3. 作成されるリソースを確認（実際には何も変更しない）
terraform plan

# 4. リソースを作成
terraform apply
# → "yes" と入力して確定

# 5. 生成されたファイルを確認
cat outputs/hello.txt
cat outputs/config.json

# 6. State ファイルを確認（Terraform が追跡している状態）
cat terraform.tfstate

# 7. main.tf を変更して再度 plan/apply で差分を体験する

# 8. 後片付け
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

## 確認ポイント

- `terraform plan` の `+` / `-` / `~` の意味を理解する
  - `+` 追加、`-` 削除、`~` 変更（in-place）、`-/+` 再作成
- `terraform.tfstate` の中身を見て、State が何を記録しているか確認する
- `main.tf` の `content` を変更して `terraform plan` を実行し、差分が表示されることを確認する

## 次のステップ

→ [フェーズ2：変数・出力・データソース](../README.md#フェーズ2変数出力データソース)
