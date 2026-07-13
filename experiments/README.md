# 実験ログ

Loop engineering / HOTL の検証実験の記録置き場。全体計画は [docs/validation-plan.md](../docs/validation-plan.md)。

## 実験の回し方

1. **起票**: Issue テンプレート「Experiment」で仮説・方法・メトリクス・成功基準を定義し、`experiments/EXX-<name>.md` を作る(C0)
2. **実施**: 実験対象のタスクを `agent:task` Issue に分解してループに流す
3. **記録**: 実施中の観察(介入した箇所、失敗、想定外)を EXX ファイルに追記。定量値は `metrics/loop-log.csv` へ
4. **判定と反映**: 成功基準と突き合わせ、**学びを反映先(CLAUDE.md / loop/ / テンプレート)への PR にする**。実験は「学びが恒久ファイルに反映されたら」完了

## 一覧

| ID | 名前 | 状態 | 学びの反映先 |
|---|---|---|---|
| [E01](E01-remote-core-loop.md) | リモートコアループ | **完了(成功)** — 3/3 マージ、タッチ 2 回/PR、CI 初回 green 3/3 | 反映済み: CLAUDE.md、metrics/README、agent-task テンプレ |
| E02 | アプリ殻とシミュレータ CI | 未着手(P1) | XcodeGen 設定, CI |
| E03 | HOTL ゲート運用 | 未着手(P1、E01 と並行可) | approval-policy |
| E04 | TestFlight パイプライン | 未着手(P2) | fastlane 設定, secrets 手順 |
| E05 | 改善メタループ | 計測中 — L4 1 周目を 2026-07-12 実施 | loop-spec, 週次レビュー手順 |
| E06 | 2本目立ち上げ | 未着手(P3) | テンプレートリポジトリ |
