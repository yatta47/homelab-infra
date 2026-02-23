---
title: "CloudWatch Billingメトリクスの取得はほぼ無料"
type: discovery
tags: [aws, cloudwatch, billing, grafana]
created: 2026-02-23
source: session
---

GrafanaからCloudWatch Billingメトリクスを取得する場合のコスト:

- CloudWatch Billing メトリクス自体: 無料（AWS標準提供）
- GetMetricData API呼び出し: 月100万リクエストまで無料枠
- Grafanaで5分間隔ポーリングでも月約8,600リクエスト → 無料枠内

一方、AWS Cost Explorer APIは1リクエスト $0.01 かかるので注意。

Billingメトリクスはus-east-1リージョンにのみ存在し、AWS Billing設定で「CloudWatchに請求メトリクスを受信する」を有効化する必要がある。

Organizations環境では `LinkedAccount` ディメンションでアカウント別の内訳も取得可能。
