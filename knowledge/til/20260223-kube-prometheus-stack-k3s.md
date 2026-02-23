---
title: "kube-prometheus-stack を k3s で使う時の注意点"
type: discovery
tags: [kube-prometheus-stack, k3s, argocd, prometheus]
created: 2026-02-23
source: session
---

kube-prometheus-stack を k3s + ArgoCD で使う際に必要な設定:

1. **ServerSideApply=true** が必須。kube-prometheus-stack の CRD（PrometheusRule 等）が大きく、client-side apply だと `metadata.annotations too long` エラーになる。

2. **k3s 固有コンポーネントの無効化**が必要:
   ```yaml
   kubeEtcd:
     enabled: false
   kubeScheduler:
     enabled: false
   kubeControllerManager:
     enabled: false
   kubeProxy:
     enabled: false
   ```
   k3s はこれらをバイナリに内蔵しており、標準のメトリクスエンドポイントが存在しない。有効のままだと ServiceMonitor のターゲットが見つからずアラートが発生する。

3. **ストレージ**: k3s にはデフォルトで `local-path` StorageClass がある。追加のプロビジョナーなしで Prometheus の PVC が使える。

## 参考

- https://artifacthub.io/packages/helm/prometheus-community/kube-prometheus-stack
