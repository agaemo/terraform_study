# phase3: モジュール化

共通のインフラパターンをモジュールとして切り出し、複数の環境で再利用する。
「dev 環境と stg 環境で同じ S3 バケット構成を使い回す」ユースケースで学ぶ。

## 学習目標

1. モジュールを自作して共通パターンを切り出す
2. 同一モジュールを複数回インスタンス化する
3. モジュールの入力（variables）と出力（outputs）の設計を理解する
4. `count` や `for_each` でリソースを動的に生成する

## 前提

LocalStack が起動していること：

```bash
# リポジトリルートで実行
docker compose up -d
```

## 実行手順

```bash
cd phase3/

terraform init

# dev / stg 両環境のバケットが計画されることを確認
terraform plan

terraform apply

# 両環境のバケットを確認
aws --endpoint-url=http://localhost:4566 s3 ls

# モジュールのリソースは "module." プレフィックスで参照される
terraform state list

# 後片付け
terraform destroy
```

## ファイル構成

```
phase3/
├── README.md
├── main.tf                    # ルートモジュール（モジュールを呼び出す側）
├── variables.tf
├── outputs.tf
└── modules/
    └── s3_bucket/             # 自作モジュール
        ├── main.tf            # モジュールの実装
        ├── variables.tf       # モジュールの入力変数
        └── outputs.tf         # モジュールの出力値
```

## 確認ポイント

- `terraform state list` でモジュール内のリソースが `module.<name>.<type>.<name>` 形式で表示される
- モジュールは「変数で設定を外部化した再利用可能な Terraform の塊」
- 呼び出し側からはモジュールの内部実装を知らなくてもいい（カプセル化）
- `for_each` でマップを使うと、複数の似たリソースをシンプルに記述できる

## モジュールの設計原則

> **「呼び出し側が知るべきことだけを variable にする」**
> - 内部の命名規則・タグ付けなどは locals でモジュール内に隠蔽する
> - 呼び出し側に判断させる設定だけを variable として公開する

## 次のステップ

→ [ベストプラクティス](../best_practices/README.md)
