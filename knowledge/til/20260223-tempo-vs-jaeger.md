---
title: "Tempo は Jaeger の後継的立ち位置（インデックス不要が最大の違い）"
type: comparison
tags: [observability, tracing, tempo, jaeger, grafana]
created: 2026-02-23
source: session
---

選択肢: Jaeger vs Tempo（分散トレーシング）

判断基準:
- Jaeger: Elasticsearch か Cassandra が必要（インデックス用）。運用コストが高い
- Tempo: インデックス不要。オブジェクトストレージやローカルディスクに直接書き込む。軽量

結論: Grafana スタック（LGTM）を使っているなら Tempo 一択。Grafana とネイティブ統合されており、メトリクス → トレースのシームレスな連携ができる。homelab のようなリソースが限られた環境では特に Tempo の軽量さが活きる。
