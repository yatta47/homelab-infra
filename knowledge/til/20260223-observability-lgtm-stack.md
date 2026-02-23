---
title: "Observability は Grafana LGTM スタック + OpenTelemetry に収束しつつある"
type: discovery
tags: [observability, grafana, opentelemetry, lgtm]
created: 2026-02-23
source: session
---

2025-2026 年の Observability トレンド:

- **OpenTelemetry** が事実上の標準に。GitHub コミット数が前年比 45% 増
- **LGTM スタック** が Grafana エコシステムの中核:
  - L: Loki（ログ）
  - G: Grafana（可視化）
  - T: Tempo（トレース）
  - M: Mimir（メトリクス、Prometheus 互換）
- AI × Observability: 84% の組織が検討/パイロット中（2025年調査）

homelab での発展パス:
1. kube-prometheus-stack (M + G) ← 今ここ
2. Loki (L) ← 次のステップ
3. Tempo (T) ← アプリが増えたら
4. OpenTelemetry Collector で統一的にデータ収集

## 参考

- https://grafana.com/blog/2026-observability-trends-predictions-from-grafana-labs-unified-intelligent-and-open/
- https://grafana.com/observability-survey/2025/
- https://thenewstack.io/can-opentelemetry-save-observability-in-2026/
