---
title: "kube-prometheus-stackでGrafanaのenvFromSecretが効かない場合がある"
type: troubleshoot
tags: [grafana, helm, kube-prometheus-stack, kubernetes]
created: 2026-02-23
source: session
---

kube-prometheus-stack v82.2.1（Grafana subchart v11.1.8）で `grafana.envFromSecret` や `grafana.envValueFrom` を設定しても、Grafana Deploymentの `envFrom` / `env` に反映されなかった。

```yaml
# これらはすべて効かなかった
grafana:
  envFromSecret: grafana-aws-credentials
  envValueFrom:
    AWS_ACCESS_KEY_ID:
      secretKeyRef:
        name: grafana-aws-credentials
        key: AWS_ACCESS_KEY_ID
```

ArgoCD + ServerSideApply 環境でHelm templateが生成するDeploymentに含まれない。

対策: `kubectl patch` で直接 Deployment に `envFrom` を追加。

```
$ kubectl patch deployment kube-prometheus-stack-grafana -n monitoring \
  --type='json' \
  -p='[{"op":"add","path":"/spec/template/spec/containers/2/envFrom","value":[{"secretRef":{"name":"grafana-aws-credentials"}}]}]'
```

ServerSideApplyを使っている場合、手動patchしたフィールドはArgoCDの管理対象外として維持される。
