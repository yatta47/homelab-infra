# homelab-infra

ホームラボのインフラ構成をTerraformで管理するリポジトリ。

## 構成

| ディレクトリ | 内容 |
|-------------|------|
| `k3s-cluster/` | Proxmox上のk3sクラスターVM（CP1 + Worker2） |
| `gitops/` | ArgoCD GitOps管理（Traefik / ArgoCD ブートストラップ、App of Apps） |

## 環境

- **仮想化基盤**: Proxmox VE
- **Terraform Provider**: [bpg/proxmox](https://registry.terraform.io/providers/bpg/proxmox/latest) v0.96+
- **ネットワーク**: 192.168.100.0/24 (vnet1)

## 使い方

各ディレクトリにREADMEがあるので参照。基本的な流れ:

```bash
cd k3s-cluster/
cp terraform.tfvars.example terraform.tfvars
# terraform.tfvars を編集（APIトークン等）

terraform init
terraform plan
terraform apply
```

## セキュリティ

- `terraform.tfvars`（APIトークン等の秘密情報）は `.gitignore` で除外
- `terraform.tfvars.example` にサンプル値を記載（コピーして使う）
- ProxmoxエンドポイントはプライベートIP（外部公開なし）
