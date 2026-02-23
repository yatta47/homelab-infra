---
title: "systemd_exporterはシステムとユーザーで別インスタンスが必要"
type: discovery
tags: [systemd, prometheus, monitoring]
created: 2026-02-23
source: session
---

`systemd_exporter` はデフォルトでシステムレベル（PID 1）のsystemdにのみ接続する。ユーザーレベル（`systemctl --user`）のタイマーやサービスは対象外。

ユーザーレベルも監視するには `--systemd.collector.user` フラグ付きの別インスタンスが必要。1プロセスで両方は取得できない。

構成例:
- ポート9558: システムレベル（systemdサービスとして起動）
- ポート9559: ユーザーレベル（systemd userサービスとして起動）

Prometheus側も `external-systemd`（システム）と `external-systemd-user`（ユーザー）の2ジョブが必要。
