---
title: "Claude Code/Codexのサブスクリプション利用ではUsage APIがない"
type: discovery
tags: [claude-code, codex, monitoring]
created: 2026-02-23
source: session
---

Claude Code（Max サブスクリプション）やCodex（ChatGPT Plus等）をサブスクリプションで利用している場合、トークン使用量等をプログラムから取得するAPIは提供されていない。

APIキー利用であればUsage APIで取得可能だが、サブスクリプションではコンソール上の表示のみ。

Grafanaダッシュボードでの自動可視化は現時点では不可。APIキーに切り替えれば対応可能。
