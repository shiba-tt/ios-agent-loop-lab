# メトリクス

ループの健全性を測る実行ログ。**「どれだけ自動化できたか」ではなく「どこで人間が必要になったか」を可視化する**(参照レポートの中心的指標)。

## loop-log.csv の列定義

| 列 | 意味 |
|---|---|
| `date` | 完了日(YYYY-MM-DD) |
| `ref` | PR/Issue 番号(例: PR#12) |
| `task` | 一言サマリ |
| `change_class` | C0/C1/C2/C3([approval-policy](../loop/approval-policy.md)) |
| `agent_env` | remote-linux / remote-macos / local-mac / human-only |
| `ci_runs` | CI 実行回数 |
| `ci_failures` | うち失敗回数(0 なら初回 green) |
| `human_touches` | 人間の介入回数(レビュー、マージ、修正指示、手動修正…) |
| `human_minutes` | 人間が使った時間(分、概算) |
| `outcome` | merged / abandoned / escalated |
| `notes` | 特記(flake、差し戻し理由、所要時間など) |

## 記録ルール

- タスクを完了させたエージェント(または人間)が、その PR 内で 1 行追記する(PR テンプレートのチェック項目)
- 正確さより継続を優先。概算で良い

## 週次レビュー(L4)の手順

1. 直近 1 週間の行を眺め、`human_touches` が多かった行・`escalated` 行・`ci_failures` が多い行を特定
2. 「なぜ人間が必要になったか」を 1 行で分類(仕様曖昧 / 検証不足 / 権限境界 / flake / その他)
3. 分類ごとに反映先(CLAUDE.md / loop-spec / approval-policy / テンプレート)への改善 PR をエージェントに起案させる(C2)
4. 週次サマリ(平均 touches、初回 green 率、コスト)を experiments/ の該当実験に追記
