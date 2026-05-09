# phase2: 変数・出力・データソース

LocalStack を使って AWS S3 バケットを作成する。
変数・ローカル値・データソースで設定を柔軟に管理する方法を学ぶ。

## 学習目標

1. `locals` で中間値を計算して重複を排除する
2. `data` ソースで既存リソースの情報を参照する
3. `output` で他のモジュールや CLI に値を公開する
4. `terraform.tfvars` で変数値を環境ごとに切り替える

## 前提

LocalStack が起動していること：

```bash
# リポジトリルートで実行
docker compose up -d
```

## 実行手順

```bash
cd phase2/

terraform init
terraform plan

# デフォルト（dev 環境）で apply
terraform apply

# バケット一覧を LocalStack で確認
aws --endpoint-url=http://localhost:4566 s3 ls

# 出力値を確認
terraform output

# stg 環境の設定で差分を確認
terraform plan -var="environment=stg"

# 後片付け
terraform destroy
```

## ファイル構成

```
phase2/
├── README.md
├── main.tf           # S3 バケットとバケットポリシー
├── variables.tf      # 入力変数
├── locals.tf         # ローカル値（中間計算）
├── data.tf           # データソース（既存リソースの参照）
├── outputs.tf        # 出力値
└── terraform.tfvars.example  # 変数ファイルのサンプル
```

## 確認ポイント

- `locals` と `variables` の使い分けを理解する
  - `variable`: 外部から渡せる入力値
  - `local`: 設定ファイル内で計算・加工した中間値（外部から変更不可）
- `data` ソースは「既に存在するリソース」を参照するための仕組み
- `terraform output -json` で出力値を JSON として取得できる

## 次のステップ

→ [フェーズ3：モジュール化](../phase3/README.md)
