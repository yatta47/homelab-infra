---
title: "sudo helm は KUBECONFIG を引き継がない"
type: troubleshoot
tags: [k3s, helm, kubeconfig]
created: 2026-02-23
source: session
---

`sudo helm install` を実行したらエラー:

```
$ sudo helm install traefik traefik/traefik --namespace traefik ...
Error: INSTALLATION FAILED: Kubernetes cluster unreachable: Get "http://localhost:8080/version": dial tcp 127.0.0.1:8080: connect: connection refused
```

原因: `sudo` は環境変数をリセットするため、k3s の kubeconfig パス (`/etc/rancher/k3s/k3s.yaml`) が Helm に渡らない。

対策: `KUBECONFIG` を明示的に指定する。

```
$ sudo KUBECONFIG=/etc/rancher/k3s/k3s.yaml helm install traefik ...
```

または `export KUBECONFIG=...` してから `sudo -E` で環境変数を引き継ぐ。
