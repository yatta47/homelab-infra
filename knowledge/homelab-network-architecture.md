# Homelab ネットワークアーキテクチャ

## 全体構成

```
ブラウザ
    │
    ▼
AdGuard DNS
    │  *.homelab.local → 192.168.100.110 (Traefik)
    │  その他 → NPM
    ▼
┌──────────────┐    ┌──────────────────────────────┐
│  NPM         │    │  k3s クラスター                │
│  (k8s の外)   │    │                              │
│              │    │  Traefik (Ingress Controller) │
│  - SSL終端   │    │    │                          │
│  - 既存サービス│    │    ├→ ArgoCD                  │
│    の振り分け │    │    ├→ Grafana (将来)           │
│              │    │    └→ その他 k8s サービス       │
└──────────────┘    └──────────────────────────────┘
```

## コンポーネントの役割

| コンポーネント | レイヤー | 役割 | 所在 |
|--------------|---------|------|------|
| AdGuard | DNS | 名前解決。ワイルドカードで Traefik に向ける | k8s 外 |
| NPM | L7 | 非 k8s サービスのリバースプロキシ + SSL終端 | k8s 外 |
| Cilium | L3/L4 | CNI。Pod 間ネットワーク通信の基盤 | k8s 内 |
| MetalLB | L4 | Service type=LoadBalancer に外部 IP を割り当て | k8s 内 |
| Traefik | L7 | Ingress Controller。ホスト名で Pod に振り分け | k8s 内 |
| Ingress | - | Traefik に渡す「ホスト名→Service」のルール定義 | K8s リソース |

## 重要な関係性

### NPM と Traefik
- 同じ立ち位置（リバースプロキシ + ホスト名振り分け）
- NPM は k8s 外のサービスを担当、Traefik は k8s 内を担当
- 違い: Traefik は Ingress リソースを自動で読み取る（GitOps と相性が良い）
- NPM は UI で手動設定

### MetalLB と Cilium LB-IPAM
- どちらも「Service に外部 IP を配る」同じ役割
- Cilium を CNI に使っているなら Cilium LB-IPAM で MetalLB を代替可能
- 現状は MetalLB を使用中。将来の整理ポイント

### 名前解決の流れ
- AdGuard に `*.homelab.local → 192.168.100.110` のワイルドカード 1 行を設定
- サービス追加時は k8s 側で Ingress を追加するだけ（AdGuard の変更不要）
- Git push → ArgoCD が同期 → Ingress 追加 → Traefik が自動検知

## HTTPS 戦略（将来: Issue #11）
- cert-manager + Let's Encrypt (DNS-01) を k8s 内に独立導入
- NPM の証明書とは別管理（サブドメインで分離: 例 `*.k8s.example.com`）
- Traefik で SSL 終端
- NPM で既に DNS-01 を使用中なので、ドメインのサブドメイン分離が必要

## IP アドレス情報

| リソース | IP |
|---------|-----|
| k3s CP | 192.168.100.101 |
| k3s Worker 1 | 192.168.100.102 |
| k3s Worker 2 | 192.168.100.103 |
| MetalLB プール | 192.168.100.110-120 (11個) |
| Traefik 外部 IP | MetalLB プールから割り当て |
