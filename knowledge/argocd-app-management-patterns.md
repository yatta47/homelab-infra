# ArgoCD アプリ管理パターン

## 自分の理解

ディレクトリ配下にファイル単位で見るか、ディレクトリ単位で見るかっていう違い。

## 3つのパターン

### 1. App of Apps（今回採用）

```
root-app → templates/ 配下の YAML ファイルを自動検知
```

- アプリ追加 = YAML ファイル1つ追加
- シンプルで理解しやすい。小〜中規模向き
- ArgoCD 公式ドキュメントにも記載されている定番

### 2. ApplicationSet（公式が最も推奨）

```
ApplicationSet → 条件に合うディレクトリごとに Application を自動生成
```

- アプリ追加 = ディレクトリ1つ追加
- テンプレート化されていて DRY
- 複数クラスター・複数環境のスケールに強い

### 3. Helm Umbrella Chart（非推奨寄り）

- 親 Helm chart の dependencies に子チャートを列挙
- ArgoCD 公式はアンチパターン寄りと指摘

## 比較

| | App of Apps | ApplicationSet | Helm Umbrella |
|---|---|---|---|
| 複雑さ | 低い | 中程度 | 高い |
| スケール | 小〜中 | 大規模対応 | 中 |
| アプリ追加 | YAML 1ファイル追加 | ディレクトリ追加 | Chart.yaml 編集 |
| 公式推奨度 | 定番 | 最も推奨 | 非推奨寄り |

## 今回の判断

homelab でクラスター1つ、アプリ数も限られるので App of Apps で十分。将来アプリが増えたら ApplicationSet に移行（templates/ 内の YAML をテンプレートに置き換えるだけ）。

## 参考

- https://codefresh.io/blog/how-to-structure-your-argo-cd-repositories-using-application-sets/
- https://wyssmann.com/blog/2025/01/how-to-organize-application-and-application-sets-in-argocd/
- https://codefresh.io/blog/argo-cd-anti-patterns-for-gitops/
- https://developers.redhat.com/articles/2023/05/25/3-patterns-deploying-helm-charts-argocd
