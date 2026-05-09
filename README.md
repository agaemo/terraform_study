# Terraform学習

IaC（Infrastructure as Code）の考え方・技術をゼロから学ぶためのリポジトリ。

> **注意：** このリポジトリは個人学習用に Claude Code を使って作成したものです。内容の正確性は完全には保証されていません。公式ドキュメントなど一次情報と照らし合わせながら学習することを推奨します。

---

## 参考文献

| 資料 | URL |
|------|-----|
| Terraform 公式ドキュメント | https://developer.hashicorp.com/terraform/docs |
| HashiCorp Tutorials（ハンズオンチュートリアル） | https://developer.hashicorp.com/terraform/tutorials |
| Terraform Registry（プロバイダー・モジュール） | https://registry.terraform.io/ |
| AWS Provider ドキュメント | https://registry.terraform.io/providers/hashicorp/aws/latest/docs |

---

## 必要なツール

| ツール | 用途 | インストール |
|--------|------|-------------|
| **Docker Desktop** | LocalStack（AWS模擬環境）の起動 | https://www.docker.com/products/docker-desktop/ |
| **mise** | Terraform バージョン管理 | https://mise.jdx.dev/ |
| **Terraform** | IaC ツール本体（mise 経由でインストール） | `mise install` |

```bash
# セットアップ
mise install            # Terraform をインストール
docker compose up -d    # LocalStack を起動（phase2以降で使用）
```

---

## LocalStack について

LocalStack は、ローカルマシン上で AWS サービスを模擬（エミュレート）するツール。S3・IAM・EC2・SQS などの AWS API をローカルで動かせるため、実際の AWS アカウントなしに Terraform のコードを試せる。

Terraform や AWS CLI からは「本物の AWS」と同じ API に見えるため、コードの変更は最小限で済む。このリポジトリでは `provider "aws"` の `endpoints` を `http://localhost:4566` に向けることで LocalStack と通信している。

**実務での主な使いどころ**

| 用途 | 内容 |
|------|------|
| CI/CD パイプライン | PR ごとの自動テストを AWS コスト・速度の制約なしに実行 |
| ローカル開発環境の統一 | `docker compose up` だけで全員が同じ環境を持てる |
| オフライン開発 | インターネット接続なしで AWS を使うコードを開発・テスト可能 |

**限界**
- 無料版（Community）はサポートするサービスが限られる
- IAM の細かい挙動など、本番と完全に一致しない場合がある
- 最終的な本番確認は実際の AWS が必要

実務では「ユニットテスト・ローカル開発は LocalStack、ステージング以降は本物の AWS」という使い分けが一般的。

---

## 学習フェーズ

### はじめに：Terraform とは何か
IaC の必要性・Terraform の動作モデル・主要概念（Provider・Resource・State）を理解する。

→ [Terraform とは何か・基本概念](intro/README.md)

---

### フェーズ1：基本操作（init / plan / apply）
`local` プロバイダーでファイルを作成しながら、Terraform の操作サイクルを体験する。インフラ環境不要。

- `terraform init / plan / apply / destroy` の流れ
- State ファイルが何を記録しているか
- 変数（variables）と出力値（outputs）の基本

→ [教材を読む](phase1/README.md)

---

### フェーズ2：変数・出力・データソース
LocalStack の S3 バケットを題材に、設定の柔軟化とリソース間参照を学ぶ。

- `variables` / `locals` / `outputs` の使い分け
- `data` ソースで既存リソースを参照する
- `terraform.tfvars` で環境ごとに値を切り替える

→ [教材を読む](phase2/README.md)

---

### フェーズ3：モジュール化
共通パターンをモジュールとして切り出し、複数環境（dev / stg）に展開する。

- モジュールの作成と呼び出し
- `for_each` で複数リソースを動的に生成
- モジュールの入力・出力設計（カプセル化）

→ [教材を読む](phase3/README.md)

---

### ベストプラクティス
本番環境で Terraform を運用するための設計指針。

- Remote State とロック（チーム開発への対応）
- シークレット管理・命名規則・タグ戦略
- Workspace vs ディレクトリ分割
- CI/CD での Terraform 実行

→ [設計指針を読む](best_practices/README.md)

---

## フェーズ一覧

| フェーズ | 内容 | インフラ |
|----------|------|---------|
| [intro](intro/README.md) | IaC の必要性・Terraform の動作モデル | なし |
| [Phase 1](phase1/README.md) | init / plan / apply の基本サイクル | local プロバイダー |
| [Phase 2](phase2/README.md) | 変数・locals・data ソース | LocalStack (S3) |
| [Phase 3](phase3/README.md) | モジュール化・for_each | LocalStack (S3) |
| [Best Practices](best_practices/README.md) | Remote State・CI/CD・設計指針 | - |

---

## 学習を終えて

3つのフェーズを通じて、Terraform の核心にある問いに向き合ってきた。

- **フェーズ1**：「インフラの状態をコードで表現できるか」を手を動かして確かめる
- **フェーズ2**：「環境差異をコードで吸収できるか」を変数と locals の設計で考える
- **フェーズ3**：「同じ構成を安全に複数箇所に展開できるか」をモジュールで実現する

Terraform が目指すのは、インフラを「手順書」ではなく「状態の宣言」として管理することだ。`plan` は「これから何が起きるか」を事前に示し、`apply` はその宣言を現実に合わせる。State はその整合性を保証するための唯一の正本（source of truth）である。

手動でリソースを作ると State とズレが生じ、次の `apply` で予期しない変更が起きる。これは Kafka で Consumer がオフセットを管理しなければ重複処理が起きるのと本質的に同じ問題だ。「どの状態が正しいか」をシステムが常に把握していることが、大規模なインフラ管理の前提になる。

コードを書くとき、設計を決めるとき——「このリソースは誰が管理しているか」「State はどこにあるか」「plan の差分を読んだか」を問い続けることが、IaC を道具ではなく習慣にするということだと思う。
