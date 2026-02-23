---
title: "Cilium LB-IPAM で MetalLB を代替できる"
type: discovery
tags: [kubernetes, cilium, metallb, networking]
created: 2026-02-23
source: session
---

CNI に Cilium を使っている場合、Cilium の LB-IPAM + L2 Announcement 機能で MetalLB と同じこと（LoadBalancer Service への外部 IP 割り当て）ができる。MetalLB が不要になりコンポーネントが1つ減る。

MetalLB は 2025-2026 年でもベアメタル LB のデファクトだが、Cilium ユーザーなら統合された LB-IPAM の方がシンプル。今回の homelab k3s クラスターは Cilium を CNI に使っているので、将来の整理ポイントとして検討の余地あり。

## 参考

- https://docs.rafay.co/blog/2025/06/17/using-cilium-as-a-kubernetes-load-balancer-a-powerful-alternative-to-metallb/
