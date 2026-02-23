---
title: "k3s の kubeconfig は root 所有で kubectl に sudo が必要"
type: discovery
tags: [k3s, kubectl, kubeconfig]
created: 2026-02-23
source: session
---

k3s の kubeconfig (`/etc/rancher/k3s/k3s.yaml`) は root 所有のため、一般ユーザーで `kubectl` を実行すると permission denied になる。

```
$ kubectl get pods -n traefik
error: error loading config file "/etc/rancher/k3s/k3s.yaml": open /etc/rancher/k3s/k3s.yaml: permission denied
```

対策: `sudo kubectl` を使うか、kubeconfig をコピーする。

```bash
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
```

これで以降 `sudo` なしで `kubectl` が使える。
