# k3s Cluster on Proxmox — Terraform構成

Proxmox上にk3sクラスター（CP1 + Worker2）を構築するTerraform構成。
cloud-initでk3s / Cilium / MetalLB のインストールまで自動化。

## 前提条件

- Proxmox上にcloud-initテンプレート（VMID 9000）が存在すること
- Proxmox APIトークンが作成済みであること
- 詳細手順: `workspace/issue-187/research/setup-guide.md`

## アーキテクチャ

```
┌─────────────────────────────────────────────┐
│ Proxmox (home)                              │
│                                             │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐    │
│  │ k3s-cp1  │ │ k3s-wk1  │ │ k3s-wk2  │    │
│  │ .101     │ │ .102     │ │ .103     │    │
│  │ server   │ │ agent    │ │ agent    │    │
│  │ Cilium   │ │ Cilium   │ │ Cilium   │    │
│  │ MetalLB  │ │ MetalLB  │ │ MetalLB  │    │
│  └──────────┘ └──────────┘ └──────────┘    │
│                                             │
│  MetalLB L2: 192.168.100.110-120            │
└─────────────────────────────────────────────┘
```

| VM | IP | 役割 | スペック |
|----|----|------|---------|
| k3s-cp1 | 192.168.100.101 | Control Plane (k3s server) | 2vCPU / 4GB |
| k3s-wk1 | 192.168.100.102 | Worker (k3s agent) | 2vCPU / 4GB |
| k3s-wk2 | 192.168.100.103 | Worker (k3s agent) | 2vCPU / 4GB |

### k3s構成

- **CNI**: Cilium（Flannel無効化）
- **LB**: MetalLB L2モード（192.168.100.110-120）
- **無効化したデフォルト**: Flannel, Traefik, ServiceLB, kube-proxy network policy

## 使い方

```bash
cd scaffolding/projects/homelab-infra/k3s-cluster

# 1. 設定ファイル作成
cp terraform.tfvars.example terraform.tfvars
# terraform.tfvars を編集（APIトークン、SSH公開鍵を設定）

# 2. 初期化
terraform init

# 3. プレビュー
terraform plan

# 4. 実行
terraform apply
# cloud-initの完了まで5〜10分程度かかる

# 5. kubeconfig 取得
scp ubuntu@192.168.100.101:/etc/rancher/k3s/k3s.yaml ~/.kube/k3s-config
sed -i 's/127.0.0.1/192.168.100.101/' ~/.kube/k3s-config
export KUBECONFIG=~/.kube/k3s-config

# 6. 確認
kubectl get nodes
kubectl -n kube-system get pods -l app.kubernetes.io/name=cilium
kubectl -n metallb-system get pods
```

## 検証手順

```bash
# 全ノード Ready 確認
kubectl get nodes
# NAME       STATUS   ROLES                  AGE   VERSION
# k3s-cp1    Ready    control-plane,master   Xm    v1.xx
# k3s-wk1    Ready    <none>                 Xm    v1.xx
# k3s-wk2    Ready    <none>                 Xm    v1.xx

# Cilium 動作確認
kubectl -n kube-system get pods -l app.kubernetes.io/name=cilium

# MetalLB 動作確認（LoadBalancer IP割り当てテスト）
kubectl create deployment nginx --image=nginx
kubectl expose deployment nginx --port=80 --type=LoadBalancer
kubectl get svc nginx
# EXTERNAL-IP に 192.168.100.110 が割り当たることを確認
curl http://192.168.100.110

# テスト後のクリーンアップ
kubectl delete svc nginx
kubectl delete deployment nginx
```

## 再構築（全やり直し）

```bash
terraform destroy
terraform apply
# cloud-init が再実行され、k3s + Cilium + MetalLB が再インストールされる
```

## トラブルシューティング

```bash
# cloud-init のログ確認
ssh ubuntu@192.168.100.101
sudo cat /var/log/cloud-init-output.log

# k3s サービスのログ
sudo journalctl -u k3s -f        # CP
sudo journalctl -u k3s-agent -f  # Worker

# Cilium の状態確認
kubectl -n kube-system exec -it ds/cilium -- cilium status

# MetalLB のログ
kubectl -n metallb-system logs -l app.kubernetes.io/name=metallb
```

## SSH接続

```bash
ssh ubuntu@192.168.100.101  # CP
ssh ubuntu@192.168.100.102  # Worker1
ssh ubuntu@192.168.100.103  # Worker2
```
