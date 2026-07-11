# 環境設計 — ローカルとリモートの棲み分け

> 観点4への回答。「どこで何を動かすか」の決定ルールと進化計画。

## 決定ルール(1行)

**目・指・実機・Apple 認証情報が要る作業だけローカル、それ以外はすべてリモート。**

## 環境マトリクス

| 環境 | 何をする | なぜそこか | コスト特性 |
|---|---|---|---|
| **リモート Linux**(Claude Code on the web / ubuntu ランナー) | ドキュメント、AppCore の実装とテスト、CI/スクリプト整備、実験ログ、メトリクス集計、調査 | Swift は Linux で動く。安い・並列化できる・あなたの Mac を占有しない。**エージェントの既定の作業場** | 最安。ubuntu CI 分単価は macOS の約1/10 |
| **リモート macOS**(GitHub Actions macos ランナー) | PR 毎のシミュレータビルド/テスト(`build-for-testing`/`test-without-building` 分離)、(P2〜)archive・TestFlight アップロード | Xcode が必要だが人間は不要な作業 | 分単価が高い。**paths フィルタ+concurrency で枠を守る**(私費の無料枠/予算前提) |
| **ローカル Mac**(あなたの手元) | Xcode GUI での UI/UX 探索、SwiftUI プレビュー、実機テスト、Instruments、キーチェーン/証明書操作、App Store Connect コンソール操作、XcodeGen 初回生成 | 体験判断と Apple 認証情報はここにしかない | 電気代のみ。ただし**あなたの人時が最も高価** |
| **(P3〜検討)self-hosted Mac mini** | macOS CI の常設ランナー、署名環境の固定化 | 量産期に hosted macOS の分数課金と待ち時間が Mac mini 1台の価格を超えたら | 初期投資+保守。移行判断基準を下に定義 |

## フェーズ進化

- **P0(今)**: リモートのみ。Mac 不要で回る範囲(このラボ+AppCore)を固める。**このセッション自体が「リモート Linux 区画」の実証**(Linux コンテナで作業し、Swift の検証は CI に委ねている)
- **P1**: ローカル Mac 接続。アプリ殻を XcodeGen で作り(初回生成と動作確認はローカル)、macOS ランナーの CI を有効化
- **P2**: 署名・配布。証明書/プロファイルを GitHub Secrets(後に fastlane match)へ、ASC API key は最小権限で発行。**Account Holder 権限の操作はローカルのブラウザでのみ行い、エージェントには渡さない**
- **P3**: コストレビュー。以下の移行判断基準で self-hosted を検討

## self-hosted Mac mini への移行判断(P3 で評価)

次のいずれかを満たしたら移行を検討する:

- hosted macOS の月間課金が Mac mini の 24 分割(約 ¥4,000〜5,000/月)を継続的に超える
- CI 待ち行列がボトルネックになり、L2 のサイクルタイムが 15 分を超える日が常態化
- 署名まわりの再現性問題(キーチェーン起因の失敗)が月2回以上発生

移行時の注意(レポートより): ランナーの後片付け(証明書残留)、OS/Xcode 更新の自前保守、ジョブ間の環境汚染。

## secrets 境界

| 秘密情報 | 置き場所 | エージェントからのアクセス |
|---|---|---|
| App Store Connect API key | GitHub Secrets(リポジトリ単位、最小権限ロール) | CI 経由のみ。値は見えない |
| 配布証明書 / プロビジョニング | GitHub Secrets(P2)→ fastlane match リポジトリ(検討) | CI 経由のみ |
| Apple ID / Account Holder 資格情報 | あなたの頭とパスワードマネージャのみ | **絶対に渡さない** |
| このラボの GitHub 書き込み | Claude GitHub App(ブランチ限定) | claude/* ブランチのみ。main 直 push 不可 = ゲートの物理的強制 |

## リモート/ローカルとループの対応

| ループ | 主たる環境 |
|---|---|
| L1(エージェント内) | リモート Linux(UI タスクのみローカル Mac 上の Claude Code) |
| L2(PR 検証) | CI(ubuntu + macOS)+ レビューはどこからでも(スマホ可) |
| L3(リリース) | CI(macOS)+ HOTL ゲートはあなたのローカル/ブラウザ |
| L4(改善) | リモート Linux が集計、判断はあなた(週次) |

設計意図: **「Mac の前に座っている時間」を、UI の質と出荷判断だけに使う。** それ以外の待ち時間・繰り返し作業はすべてリモートに追い出す。
