# 外部ホストから k3s クラスターへの kubectl アクセス設定

## 前提

- k3s クラスターのコントロールプレーン: `k3s-cp1` (192.168.100.101)
- 外部ホスト（devbox など）と同一サブネット (192.168.100.0/24)
- CP ノードへの SSH アクセスが可能 (`ubuntu@192.168.100.101`)

## 手順

### 1. kubectl のインストール

```bash
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl
sudo mv kubectl /usr/local/bin/
```

### 2. kubeconfig の取得

```bash
mkdir -p ~/.kube
ssh ubuntu@192.168.100.101 sudo cat /etc/rancher/k3s/k3s.yaml > ~/.kube/k3s-config
chmod 600 ~/.kube/k3s-config
```

### 3. サーバアドレスの書き換え

kubeconfig 内の `127.0.0.1` を CP ノードの IP に変更する:

```bash
sed -i 's/127.0.0.1/192.168.100.101/' ~/.kube/k3s-config
```

### 4. KUBECONFIG 環境変数の設定

```bash
export KUBECONFIG=~/.kube/k3s-config
```

永続化する場合は `.zshrc` (または `.bashrc`) に追加:

```bash
echo 'export KUBECONFIG=~/.kube/k3s-config' >> ~/.zshrc
```

### 5. 動作確認

```bash
kubectl get nodes
kubectl get applications -n argocd
```

## 注意事項

- kubeconfig にはクラスターの認証情報が含まれるため、パーミッションは `600` にすること
- k3s の kubeconfig はデフォルトで `cluster-admin` 権限を持つ
