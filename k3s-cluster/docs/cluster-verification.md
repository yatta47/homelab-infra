# k3s クラスター構築 確認手順書

`terraform apply` 後、cloud-init が完了したことを確認してから本手順を実施する。

## 前提: cloud-init の完了確認

クラスターの確認を行う前に、全ノードの cloud-init が完了している必要がある。

```bash
# 各ノードで実行（全ノードが status: done になるまで待つ）
ssh ubuntu@192.168.100.101 'cloud-init status'
ssh ubuntu@192.168.100.102 'cloud-init status'
ssh ubuntu@192.168.100.103 'cloud-init status'
```

- `status: done` → 正常完了
- `status: running` → まだ実行中（数分待って再確認）
- `status: error` → エラーあり（ログ確認が必要）

cloud-init が running のまま長時間変わらない場合は、ログで進捗を確認する:

```bash
ssh ubuntu@192.168.100.101 'sudo tail -30 /var/log/cloud-init-output.log'
```

## 確認チェックリスト

### 1. ノード状態（必須）

**目的**: 全ノードがクラスターに参加し、正常稼働していること。

```bash
sudo kubectl get nodes
```

**期待結果**:
```
NAME      STATUS   ROLES                       AGE   VERSION
k3s-cp1   Ready    control-plane,etcd,master   Xm    v1.31.4+k3s1
k3s-wk1   Ready    <none>                      Xm    v1.31.4+k3s1
k3s-wk2   Ready    <none>                      Xm    v1.31.4+k3s1
```

**確認ポイント**:
- 3ノードすべてが表示されていること
- STATUS が全ノード `Ready` であること
- k3s-cp1 に `control-plane` ロールが付いていること

### 2. システム Pod の状態（必須）

**目的**: k3s 基盤コンポーネントがすべて稼働していること。

```bash
sudo kubectl get pods -A
```

**期待結果**: 全 Pod が `Running` であること。`Pending` / `CrashLoopBackOff` / `Error` がないこと。

**確認すべき Pod 一覧**:

| Namespace | Pod | 説明 |
|-----------|-----|------|
| kube-system | coredns-* | クラスター内 DNS |
| kube-system | metrics-server-* | メトリクス収集 |
| kube-system | local-path-provisioner-* | ローカルストレージ |
| kube-system | cilium-* | CNI（各ノードに1つ） |
| kube-system | cilium-operator-* | Cilium コントローラー |
| kube-system | cilium-envoy-* | Cilium L7 プロキシ（各ノードに1つ） |
| metallb-system | metallb-controller-* | MetalLB コントローラー（1つ） |
| metallb-system | metallb-speaker-* | MetalLB L2 応答（各ノードに1つ） |

### 3. Cilium CNI の状態（必須）

**目的**: Pod 間ネットワーク (CNI) が正常であること。

```bash
# Cilium の簡易ステータス
sudo kubectl -n kube-system exec ds/cilium -- cilium status --brief
```

**期待結果**: `OK` が返ること。

```bash
# Cilium Pod の確認
sudo kubectl -n kube-system get pods -l app.kubernetes.io/name=cilium
```

**確認ポイント**:
- 各ノードに cilium Pod が1つずつ存在すること（計3つ）
- すべて `Running` & `READY 1/1` であること

### 4. MetalLB の状態（必須）

**目的**: LoadBalancer Service に外部IPを割り当てられること。

```bash
# IPアドレスプールの確認
sudo kubectl get ipaddresspool -n metallb-system
```

**期待結果**:
```
NAME           AUTO ASSIGN   AVOID BUGGY IPS   ADDRESSES
default-pool   true          false             ["192.168.100.110-192.168.100.120"]
```

```bash
# L2 Advertisement の確認
sudo kubectl get l2advertisement -n metallb-system
```

**期待結果**: `default` という L2Advertisement リソースが存在すること。

### 5. Helm リリースの確認（必須）

**目的**: Cilium と MetalLB が Helm 経由で正しくデプロイされていること。

```bash
sudo helm list -A --kubeconfig /etc/rancher/k3s/k3s.yaml
```

**期待結果**:
```
NAME    NAMESPACE        STATUS    CHART            APP VERSION
cilium  kube-system      deployed  cilium-1.17.3    1.17.3
metallb metallb-system   deployed  metallb-0.15.3   v0.15.3
```

**確認ポイント**:
- STATUS が両方 `deployed` であること
- `failed` や `pending-install` でないこと

### 6. LoadBalancer Service の動作テスト（推奨）

**目的**: MetalLB による外部 IP 割り当てが実際に機能すること。Issue #2 の完了条件の一つ。

```bash
# テスト用 Deployment + Service を作成
sudo kubectl create deployment nginx-test --image=nginx --replicas=1
sudo kubectl expose deployment nginx-test --port=80 --type=LoadBalancer

# EXTERNAL-IP が割り当たるまで待つ（数秒）
sudo kubectl get svc nginx-test
```

**期待結果**:
```
NAME         TYPE           CLUSTER-IP     EXTERNAL-IP       PORT(S)        AGE
nginx-test   LoadBalancer   10.43.x.x      192.168.100.110   80:xxxxx/TCP   Xs
```

**確認ポイント**:
- EXTERNAL-IP に `192.168.100.110-120` 範囲のIPが割り当たること
- `<pending>` のまま止まらないこと

```bash
# クリーンアップ
sudo kubectl delete deployment nginx-test
sudo kubectl delete svc nginx-test
```

### 7. Pod スケジューリングの確認（推奨）

**目的**: Worker ノードに Pod がスケジュールされること。

```bash
sudo kubectl run test-pod --image=nginx --restart=Never
sudo kubectl get pod test-pod -o wide
```

**確認ポイント**:
- STATUS が `Running` になること
- NODE が Worker ノード（k3s-wk1 または k3s-wk2）であること

```bash
# クリーンアップ
sudo kubectl delete pod test-pod
```

## 確認結果サマリ（2026-02-23 実施）

| # | 項目 | 結果 |
|---|------|------|
| 1 | ノード状態 (3台 Ready) | OK |
| 2 | システム Pod (全 Running) | OK |
| 3 | Cilium CNI (status OK) | OK |
| 4 | MetalLB 設定 (IPPool + L2Adv) | OK |
| 5 | Helm リリース (deployed) | OK |
| 6 | LoadBalancer IP 割り当て | OK (192.168.100.110) |
| 7 | Pod スケジューリング | OK |

## VM 再構築時の注意

```bash
# VMを作り直した場合、SSHホストキーが変わるため known_hosts をクリアする
ssh-keygen -f ~/.ssh/known_hosts -R 192.168.100.101
ssh-keygen -f ~/.ssh/known_hosts -R 192.168.100.102
ssh-keygen -f ~/.ssh/known_hosts -R 192.168.100.103
```
