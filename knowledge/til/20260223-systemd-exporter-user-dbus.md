---
title: "systemd_exporter --user はD-Busユーザーバスが必要"
type: troubleshoot
tags: [systemd, prometheus, dbus, monitoring]
created: 2026-02-23
source: session
---

`systemd_exporter --systemd.collector.user` でユーザーレベルのsystemdユニットを監視しようとしたが、メトリクスが空だった。

```
$ curl -s http://localhost:9559/metrics | grep systemd_unit
（出力なし）
```

ログを確認するとD-Bus接続エラー:

```
level=ERROR source=systemd.go:265 msg="error collecting metrics" err="couldn't get dbus connection: dial unix /run/user/1000/bus: connect: no such file or directory"
```

原因: SSH経由のセッションではD-Busユーザーバスが自動起動しない。`/run/user/1000/bus` ソケットが存在しなかった。

対策:

```
$ systemctl --user start dbus.socket
```

これでバスソケットが作成され、exporterがユーザーsystemdに接続できるようになった。

また `--systemd.collector.private` オプションも試したが、`--user` と組み合わせても `/run/systemd/private`（システム側）に接続しようとするバグがあり使えなかった（v0.7.0）。

systemdユーザーサービスとして配置する場合は `Requires=dbus.socket` を追加して依存関係を設定する。
