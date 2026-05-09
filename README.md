# terraform_study

Terraform による IaC（Infrastructure as Code）を段階的に学ぶリポジトリ。

## 学習フロー

```
intro/          → Terraform の基本概念
phase1/         → 最初の設定ファイルと apply/destroy サイクル
phase2/         → 変数・出力・データソース
phase3/         → モジュール化と再利用
best_practices/ → 本番環境の設計指針
```

## セットアップ

### 必要ツール

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) – LocalStack 実行用
- [mise](https://mise.jdx.dev/) – Terraform バージョン管理
- [terraform](https://developer.hashicorp.com/terraform/install) – mise 経由でインストール

### クイックスタート

```bash
# Terraform をインストール
mise install

# LocalStack を起動（AWS 模擬環境）
docker compose up -d

# LocalStack の動作確認
curl http://localhost:4566/_localstack/health
```

LocalStack Web UI: `http://localhost:4566`

## 各フェーズの概要

| フェーズ | テーマ | インフラ |
|----------|--------|----------|
| intro | 概念理解 | なし |
| phase1 | 基本操作（init/plan/apply） | local プロバイダー |
| phase2 | 変数・出力・データソース | LocalStack (S3) |
| phase3 | モジュール化 | LocalStack (S3 + IAM) |
| best_practices | 設計指針 | - |

## コア概念

```
「インフラをコードとして宣言し、再現可能な状態を保証する」
- 手動操作は残さない
- State が現実の正本（source of truth）
- Plan で変更を確認してから Apply
```
