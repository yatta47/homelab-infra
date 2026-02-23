---
title: "MetalLB と Traefik は L4 と L7 で役割が違う"
type: discovery
tags: [kubernetes, metallb, traefik, networking]
created: 2026-02-23
source: session
---

ベアメタル k8s で MetalLB と Traefik の両方が必要な理由。

- **MetalLB**: L4。`LoadBalancer` タイプの Service に外部 IP アドレスを割り当てる。クラウドでいう AWS ELB / GCP LB の代替
- **Traefik**: L7。Ingress ルールに基づいて HTTP リクエストをホスト名で振り分ける（`argocd.homelab.local` → argocd-server 等）

MetalLB だけだとホスト名ベースのルーティングができず、Traefik だけだとベアメタル環境で外部 IP を割り当てる手段がない。両方セットで初めてクラウドと同等の Ingress が機能する。

## 参考

- https://metallb.io/
- https://www.thedougie.com/2025/06/05/kubernetes-ingress-metallb-traefik-cloudflare/
