---
title: "ArgoCD は Git を Pull する（Git → k8s ではない）"
type: discovery
tags: [argocd, gitops, kubernetes]
created: 2026-02-23
source: session
---

GitOps だから「Git 側から k8s が見える必要がある」と思いがちだが、実際は逆。

ArgoCD はクラスター内で動いていて、定期的に GitHub をポーリング（デフォルト3分間隔）してマニフェストの差分を検知する。変更があれば自動で apply する。

- **必要**: k8s → GitHub への HTTPS アウトバウンド通信（pull）
- **不要**: GitHub → k8s へのインバウンド通信

つまり NAT 内の homelab からでもそのまま使える。
