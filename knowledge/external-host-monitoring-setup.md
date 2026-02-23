# 外部ホストの Prometheus 監視セットアップ手順

k3s クラスター外のホストを kube-prometheus-stack の Prometheus で監視する手順。

## 前提

- kube-prometheus-stack が k3s クラスター内で稼働中
- 対象ホストと k3s クラスターが同一ネットワーク内（192.168.100.0/24）

## 手順

### 1. 対象ホストに node-exporter をインストール

CPU/メモリ/ディスク/ネットワークのメトリクスを収集する。

```bash
sudo apt-get install prometheus-node-exporter
sudo systemctl enable --now prometheus-node-exporter
```

確認:

```bash
curl -s http://localhost:9100/metrics | head -5
```

### 2. 対象ホストに systemd-exporter をインストール

systemd サービスの状態（起動状態、再起動回数等）を収集する。
Debian パッケージにはないため、GitHub Releases からバイナリを取得。

```bash
# バイナリ取得（バージョンは適宜変更）
cd /tmp
curl -LO https://github.com/prometheus-community/systemd_exporter/releases/download/v0.7.0/systemd_exporter-0.7.0.linux-amd64.tar.gz
tar xzf systemd_exporter-0.7.0.linux-amd64.tar.gz
sudo cp systemd_exporter-0.7.0.linux-amd64/systemd_exporter /usr/local/bin/
sudo chmod +x /usr/local/bin/systemd_exporter
```

systemd ユニットファイルを作成:

```bash
sudo tee /etc/systemd/system/systemd-exporter.service > /dev/null <<'EOF'
[Unit]
Description=Prometheus systemd Exporter
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/systemd_exporter
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable --now systemd-exporter
```

確認:

```bash
curl -s http://localhost:9558/metrics | head -5
```

### 3. Prometheus の scrape 設定を追加（GitOps）

`gitops/apps/templates/kube-prometheus-stack.yaml` の `valuesObject.prometheus.prometheusSpec` に `additionalScrapeConfigs` を追加:

```yaml
additionalScrapeConfigs:
  - job_name: "external-node"
    static_configs:
      - targets: ["<HOST_IP>:9100"]
        labels:
          instance: "<HOST_NAME>"
  - job_name: "external-systemd"
    static_configs:
      - targets: ["<HOST_IP>:9558"]
        labels:
          instance: "<HOST_NAME>"
```

Git push → ArgoCD が自動同期（約3分）→ Prometheus がスクレイプ開始。

### 4. 動作確認

- Grafana (`http://grafana.homelab.local`) で対象ホストのメトリクスが表示されること
- Dashboards → 「Node Exporter / Nodes」で対象ホストを選択できること

## 監視済みホスト

| ホスト名 | IP | node-exporter | systemd-exporter |
|---------|-----|--------------|-----------------|
| devbox | 192.168.100.17 | :9100 | :9558 |

## 他のホストを追加する場合

1. 対象ホストで手順 1〜2 を実施
2. `additionalScrapeConfigs` の `targets` にホストを追加して Git push

## 参考

- https://github.com/prometheus-community/systemd_exporter
- https://github.com/prometheus/node_exporter
