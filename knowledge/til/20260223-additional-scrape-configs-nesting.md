---
title: "additionalScrapeConfigs は prometheus.prometheusSpec の下に書く"
type: pitfall
tags: [prometheus, kube-prometheus-stack, helm, argocd]
created: 2026-02-23
source: session
---

kube-prometheus-stack の Helm values で `additionalScrapeConfigs` を指定する際、`valuesObject` 直下に書くと Helm chart が認識せず Prometheus に反映されない。

正しくは `prometheus.prometheusSpec.additionalScrapeConfigs` にネストする必要がある。

ArgoCD 上は Synced/Healthy と表示されるため気付きにくい。Grafana で `up{job="..."}` が No data の場合、k3s CP 上で Prometheus CR を確認すると原因を特定できる。

```bash
sudo k3s kubectl get prometheus -n monitoring -o yaml | grep additionalScrapeConfigs
```
