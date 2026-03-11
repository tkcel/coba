# /morning

朝の一括処理。今日のアジェンダを生成し、準備を整える。

## 実行フロー

```
1. tmp/ 確認
      ↓ ファイルがあれば
2. [/triage-tmp] tmp → inbox 振り分け
      ↓
3. [/generate-daily] 日次アジェンダ生成（Jiraセクション含む）
      ↓
4. [slack:channel-digest] Slack の overnight まとめ
      ↓
5. [/jira-check my-tickets] + [/jira-check overdue] Jira 朝チェック
      ↓
6. サマリー報告
```

## Slack チャンネルダイジェスト

- ビルトインスキル `slack:channel-digest` を使って、前日夜〜今朝の Slack アクティビティをまとめる
- 重要な未読や自分宛のメンションがあれば強調する
- Slack 連携が未設定の場合はスキップ

## Jira 朝チェック

以下の Jira スキルを順番に呼び出す:

1. `/jira-check my-tickets` — 自分のオープンチケット一覧
2. `/jira-check overdue` — 期限切れチケットの警告

- Jira 未設定の場合はスキルがスキップを返すのでそのまま次へ進む

## サマリー報告フォーマット

```
## おはようございます！

### 今日の準備完了

📅 予定: X件
📋 持ち越しタスク: X件
🎫 Jira: Xチケットオープン / Y件期限超過
💬 Slack: X件の動きあり

### スケジュール
| 時間 | 予定 |
|------|------|
| 09:00 | 朝礼 |
| 10:00 | 開発定例 |
| ... |

### Jira チケット
| キー | タイトル | ステータス | 優先度 | 期限 |
|------|---------|----------|--------|------|
| PROJ-123 | ○○の実装 | In Progress | High | 03/15 |

⚠️ 期限超過: PROJ-456（03/08期限）

### Slack まとめ
- #general: ○○についてのアナウンス
- #dev: △△のPRがマージされた
- @メンション: □□さんから質問あり

何から始めますか？
```

## ルール

- `tmp/` にファイルがあれば先に振り分け
- `/generate-daily` で今日のアジェンダを生成
- 既に `daily/YYYY-MM-DD.md` がある場合は上書きせず確認
- Slack 連携が有効なら `slack:channel-digest` でオーバーナイトの動きを取得
- 秘書の口調で報告（`.claude/rules/secretary.md` 参照）
