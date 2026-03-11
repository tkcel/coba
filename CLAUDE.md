# COBA - AI協働ワークスペース

日常業務をAIと一緒に進めるためのワークスペース。
「tmp に落とせば、あとはAIがやってくれる」が基本思想。

## フォルダ構成

```
coba/
├── tmp/           ← ここにファイルを落とす（入口）
├── inbox/         ← 分類・整形されたファイル
│   ├── meetings/  ← 議事録
│   ├── tasks/     ← TODO・タスク
│   ├── notes/     ← メモ・アイデア
│   └── other/     ← 分類できなかったもの
├── daily/         ← 日次アジェンダ
├── weekly/        ← 週次サマリー
└── knowledge/     ← 蓄積ナレッジ
    ├── me.md        ← オーナー情報（自分自身）
    ├── people.md
    ├── glossary.md
    └── decisions/   ← 意思決定ログ（1件1ファイル）
```

## 秘書

`/secretary` でいつでも秘書に相談できる。

- 窓口として何でも相談OK
- 判断・ルーティングを行い、適切なスキルを自動呼び出し
- TODO管理、壁打ち、メモ、予定確認
- Jiraチケット操作（`scripts/jira.sh`）、Slack連携

## スキル一覧

| コマンド | 説明 |
|----------|------|
| `/secretary` | 秘書（窓口・オーケストレーター） |
| `/onboarding` | 初期セットアップ |
| `/morning` | 朝の一括処理 |
| `/evening` | 夕方の一括処理 |
| `/triage-tmp` | tmp振り分け |
| `/format-meeting` | 議事録整形 |
| `/extract-todo` | TODO抽出 |
| `/generate-daily` | 日次アジェンダ生成 |
| `/generate-weekly` | 週次サマリー生成 |
| `/capture-memo` | クイックメモ |
| `/brainstorm` | 壁打ち・相談 |
| `/optimize-rules` | ルール最適化 |

## 基本ルール

- 日本語で作業
- ファイルの削除は禁止。移動・上書きのみ
- 情報が不足している項目は「要確認」と明記（推測で埋めない）
- ユーザーから明示的に指示されない限り、git commit しない
