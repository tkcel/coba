# /evening

夕方の一括整理。tmp振り分け → 議事録整形 → TODO抽出 → スタンドアップ生成 を連続実行する。

## 実行フロー

```
1. tmp/ のファイル確認
      ↓
2. [/triage-tmp] tmp → inbox 振り分け
      ↓
3. [/format-meeting] inbox/meetings/ の未整形ファイルを整形
      ↓
4. [/extract-todo] 整形済み議事録からTODO抽出
      ↓
5. [/jira-check today] + [/jira-update-ticket] Jira チケット状況確認
      ↓
6. [slack:standup] 今日のスタンドアップを生成
      ↓
7. サマリー報告
      ↓
8. 週末（金〜日）なら [/generate-weekly]
```

## スタンドアップ生成

- ビルトインスキル `slack:standup` を使って、今日の Slack アクティビティからスタンドアップを生成する
- 生成されたスタンドアップはサマリー内に含めて報告
- ユーザーが確認後、Slack に投稿するか選べるようにする
- Slack 連携が未設定の場合はスキップ

## Jira チケット状況確認

以下の Jira スキルを順番に呼び出す:

1. `/jira-check today` — 今日更新されたチケット一覧
2. `/jira-update-ticket` — ステータス変更が必要そうなチケットを提案、ユーザー確認後に実行

- Jira 未設定の場合はスキルがスキップを返すのでそのまま次へ進む

## サマリー報告フォーマット

```
## 夕方まとめ完了

### 振り分け結果
- meetings: X件
- tasks: X件
- notes: X件
- other: X件

### 整形した議事録
- YYYY-MM-DD_会議名.md
- ...

### 抽出したTODO
- [ ] タスク内容（担当: XX）
- [ ] ...

### Jira チケット（今日の動き）
| キー | タイトル | 変更内容 |
|------|---------|---------|
| PROJ-123 | ○○の実装 | In Progress → Done |

→ PROJ-456 を Done にしますか？

### 今日のスタンドアップ
（slack:standup の結果）
→ Slack に投稿しますか？
```

## 週末バリエーション（金・土・日）

週末に実行した場合は、上記に加えて `/generate-weekly` も実行する。

```
### 週次サマリー
weekly/YYYY-Www.md を生成しました。

今週の振り返り:
- MTG参加数: XX件
- タスク完了: XX件
```

## ルール

- 各ステップで処理対象がなければスキップ
- エラーが発生しても次のステップに進む（エラー内容は最後に報告）
- `tmp/` が空なら「tmp は空です」と報告してスキップ
- Slack 連携が有効なら `slack:standup` でスタンドアップを生成
- スタンドアップの Slack 投稿はユーザー確認後に行う
- 処理完了後、明日の予定があれば簡単に触れる
- 秘書の口調で報告（`.claude/rules/secretary.md` 参照）
