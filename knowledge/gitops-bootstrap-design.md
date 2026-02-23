# GitOps ブートストラップ設計

## ブートストラップ順序

```
[既存] cloud-init → k3s → Cilium → MetalLB
[手動] Helm       → Traefik → ArgoCD
[自動] ArgoCD     → kube-prometheus-stack, cert-manager 等
```

## 設計判断

### なぜ Traefik が先か
- ArgoCD UI の Ingress に Traefik が必要
- Traefik → ArgoCD の順でインストール

### なぜ手動 Helm か
- cloud-init: VM 作成時に 1 回だけ。Helm install 失敗時の調査が困難
- Ansible: リポジトリに土台がない。1回きりの作業に導入コストが大きい
- Terraform provisioner: apply のたびに再実行リスク
- → 詳細は decision-automate-vs-manual.md 参照

### App of Apps パターン
- `gitops/apps/root-app.yaml` がルート Application
- `gitops/apps/templates/` 内の Application マニフェストを自動同期
- `prune: true` + `selfHeal: true` を有効化
- **注意**: templates/ が空の状態で root-app を適用しないこと

## Helm chart バージョン（検証済み）
- Traefik: 39.0.2
- ArgoCD: 9.4.4

## 関連 Issue
- #4: ArgoCD を k3s クラスターにデプロイする
- #11: cert-manager 導入で HTTPS 化
