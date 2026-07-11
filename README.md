# ios-agent-loop-lab

iOS アプリ開発における **Loop engineering / Human-on-the-loop (HOTL)** の検証ラボ。

目的: AI エージェントと人間の分業ループを設計・計測・改善し、**個人開発(副業)で iOS アプリを量産・改善するための検証済みループ一式(App Factory Kit)** を手に入れる。理論的背景は [参照レポート](docs/references/deep-research-report.md)。

## 基本方針(3層モデル)

1. **自動実行層** — エージェントが実装・テスト・CI 修正・ドラフト作成を回す(既定はリモート Linux)
2. **HOTL 制御層** — 人間は承認ゲート(コードレビュー、外部配布、ストア提出、公開)と停止権限を持つ
3. **評価・改善層** — 介入回数・CI 失敗・コストを記録し、週次でループ自体を改善する

「自動化率」ではなく **停止可能性・監査可能性・再現性** を優先する(参照レポートの結論)。

## ドキュメントマップ

| ドキュメント | 内容 |
|---|---|
| [docs/loop-design.md](docs/loop-design.md) | **ループ設計** — L1〜L4 の 4 層ループと SwiftPM コア分離アーキテクチャ |
| [docs/validation-plan.md](docs/validation-plan.md) | **検証計画** — リサーチクエスチョン、実験 E01〜E06、副業 KPI への接続 |
| [docs/roles-and-gates.md](docs/roles-and-gates.md) | **役割分担** — AI と人間の分担表、承認疲れ対策、エスカレーション規則 |
| [docs/environments.md](docs/environments.md) | **環境設計** — ローカル / リモートの棲み分け、secrets 境界、Mac mini 移行判断 |
| [loop/loop-spec.yaml](loop/loop-spec.yaml) | ループ仕様(トリガー / 完了条件 / 停止条件 / 権限) |
| [loop/approval-policy.md](loop/approval-policy.md) | 変更クラス C0〜C3 と HOTL ゲート |
| [CLAUDE.md](CLAUDE.md) | エージェント作業契約 |
| [experiments/](experiments/README.md) | 実験ログ |
| [metrics/](metrics/README.md) | 実行記録と週次レビュー手順 |

## いま何がある(P0)

- ループの設計・仕様・ポリシー・テンプレート一式
- `packages/AppCore` — **Linux で `swift test` が通る**純 Swift コア(SwiftPM 分離アーキテクチャの最小実証)
- CI: `core-ci`(ubuntu + Swift コンテナで AppCore をテスト)、`docs-ci`(YAML / 構造検証)

## クイックスタート(人間向け)

1. **初期セットアップ PR をレビュー・マージする**(最初の HOTL ゲート)
2. リポジトリの Settings で default branch が `main` であることを確認する
3. **E01 を開始する**: Issue テンプレート「Agent Task」で最初のタスクを起票し、Claude Code(web)のセッションに渡す。詳細は [experiments/E01-remote-core-loop.md](experiments/E01-remote-core-loop.md)
4. 週次 15〜30 分で [metrics/README.md](metrics/README.md) の L4 レビューを回す

## ロードマップ

| フェーズ | 内容 | 実験 |
|---|---|---|
| **P0(現在)** | ラボ基盤 + リモートのみで L1/L2 検証 | E01 |
| P1 | アプリ殻(XcodeGen + SwiftUI)、macOS ランナー CI、HOTL ゲート運用 | E02, E03 |
| P2 | fastlane + App Store Connect API key、TestFlight 内部配布の完全自動化 | E04 |
| P3 | 改善メタループ定常化、テンプレートリポジトリ切り出し、2 本目のアプリ | E05, E06 |
