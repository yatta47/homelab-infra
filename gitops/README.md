# gitops/

ArgoCD による GitOps 管理の構成ディレクトリ。

## ディレクトリ構成

```
gitops/
├── README.md                   # このファイル
├── bootstrap/                  # 手動Helmインストールする基盤コンポーネント（参照用）
│   ├── traefik/
│   │   └── values.yaml         # Traefik Helm values
│   └── argocd/
│       ├── values.yaml         # ArgoCD Helm values
│       └── ingress.yaml        # ArgoCD Ingress マニフェスト
├── apps/
│   ├── root-app.yaml           # App of Apps ルート Application
│   └── templates/              # 個別の Application 定義
└── manifests/                  # 生の K8s マニフェスト（各アプリ用）
```

## ブートストラップ順序

```
[既存] cloud-init → k3s → Cilium → MetalLB
[手動] Helm       → Traefik → ArgoCD
[自動] ArgoCD     → kube-prometheus-stack 等
```

Traefik を先にインストールする理由: ArgoCD UI の Ingress に必要なため。

## ブートストラップ手順（CPノードで実行）

### 1. Traefik インストール

```bash
sudo helm repo add traefik https://traefik.github.io/charts
sudo helm repo update
sudo helm install traefik traefik/traefik \
  --namespace traefik --create-namespace \
  -f /path/to/gitops/bootstrap/traefik/values.yaml \
  --wait --timeout 120s
```

確認:

```bash
kubectl get pods -n traefik
kubectl get svc -n traefik    # EXTERNAL-IP が MetalLB から割り当てられること
```

### 2. ArgoCD インストール

```bash
sudo helm repo add argo https://argoproj.github.io/argo-helm
sudo helm repo update
sudo helm install argocd argo/argo-cd \
  --namespace argocd --create-namespace \
  -f /path/to/gitops/bootstrap/argocd/values.yaml \
  --wait --timeout 300s
```

### 3. ArgoCD Ingress 作成

```bash
sudo kubectl apply -f /path/to/gitops/bootstrap/argocd/ingress.yaml
```

ワークステーションの `/etc/hosts` に Traefik の外部 IP を追記:

```
<TRAEFIK_EXTERNAL_IP>  argocd.homelab.local
```

### 4. ArgoCD 初期パスワード取得

```bash
sudo kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d && echo
```

- ユーザー名: `admin`
- ブラウザで `http://argocd.homelab.local` にアクセス

### 5. App of Apps ルートアプリケーション登録

> **注意**: リポジトリが private の場合、先に ArgoCD UI または CLI で GitHub PAT を登録する必要あり。

```bash
sudo kubectl apply -f /path/to/gitops/apps/root-app.yaml
```

以降は `gitops/apps/templates/` に Application マニフェストを追加し、Git push するだけで ArgoCD が自動同期する。

## 確認ポイント

| # | 項目 | コマンド |
|---|------|---------|
| 1 | Traefik Pod Running | `kubectl get pods -n traefik` |
| 2 | Traefik に外部IP割り当て | `kubectl get svc -n traefik` |
| 3 | ArgoCD Pod Running | `kubectl get pods -n argocd` |
| 4 | ArgoCD UI アクセス | `curl http://argocd.homelab.local` |
| 5 | Root Application 同期 | `kubectl get applications -n argocd` |

## 備考

- TLS（HTTPS）は今回スコープ外。将来 cert-manager を ArgoCD 管理で追加可能
- MetalLB IP プールは 192.168.100.110-120（11個）。Traefik が 1 つ使用
