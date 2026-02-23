---
title: "Traefik に IP アドレスで直接アクセスすると 404 になる"
type: discovery
tags: [traefik, ingress, kubernetes]
created: 2026-02-23
source: session
---

Traefik の外部 IP（例: 192.168.100.110）にブラウザから直接アクセスすると 404 が返る。

理由: Traefik は Ingress のホスト名ベースルーティングを使っている。IP アドレスでアクセスすると HTTP リクエストの Host ヘッダーが IP アドレスになり、Ingress ルール（`host: argocd.homelab.local` 等）にマッチしない。

対策: DNS（AdGuard 等）か `/etc/hosts` でホスト名を Traefik の IP に解決させる必要がある。
