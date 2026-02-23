---
title: "k8s 外のホストを Prometheus で監視する方法"
type: discovery
tags: [prometheus, node-exporter, systemd-exporter, monitoring]
created: 2026-02-23
source: session
---

k8s クラスター外のホストを kube-prometheus-stack の Prometheus で監視するパターン:

1. 対象ホストに exporter をインストール
   - `node-exporter` (:9100) → CPU/メモリ/ディスク/ネットワーク
   - `systemd-exporter` (:9558) → systemd サービスの状態

2. Prometheus の `additionalScrapeConfigs` に targets を追加

```yaml
prometheus:
  prometheusSpec:
    additionalScrapeConfigs:
      - job_name: "external-node"
        static_configs:
          - targets: ["192.168.100.17:9100"]
            labels:
              instance: "devbox"
```

GitOps で管理している場合、Application YAML の valuesObject に追記して Git push するだけで ArgoCD が自動反映する。

Debian の場合、node-exporter は `apt install prometheus-node-exporter` で入る。systemd-exporter は GitHub Releases からバイナリを取得して systemd ユニットを手動作成する必要がある。

## 参考

- https://github.com/prometheus-community/systemd_exporter
