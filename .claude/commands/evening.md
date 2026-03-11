# /evening

夕方の一括整理。tmp振り分け → 議事録整形 → TODO抽出 を連続実行する。

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
5. [/jira-check evening] Jira チケット状況確認
      ↓
6. Slack 1日のまとめ（slack:standup）
      ↓
7. サマリー報告
      ↓
8. 週末（金〜日）なら [/generate-weekly]
```

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

### Jira
- 担当チケット: X件（うち今日更新: X件）
- ステータス変更の提案: PROJ-123 → Done にしますか？
（※ 取得できなかった場合はこのセクションを省略）

### Slack まとめ
- 今日の主なやりとり: ...
- フォローが必要なスレッド: ...
（※ 取得できなかった場合はこのセクションを省略）
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

## Jira チケット確認

`/jira-check evening` を実行する。

- 今日更新されたチケットを取得し、`daily/YYYY-MM-DD.md` の `## Jira` セクションを最終版として更新
- ステータス変更の提案があれば `/jira-update-ticket` で実行（ユーザー確認後）
- 失敗した場合はスキップ

## Slack まとめ

`slack:standup` を使い、今日1日の Slack 活動を振り返る。

- 自分が参加したスレッド、送ったメッセージの要約
- 未返信・フォローが必要なスレッドがあれば明示
- **`daily/YYYY-MM-DD.md` の `## Slack まとめ` セクションを最終版として更新する**（`.claude/rules/daily.md` の「Slack まとめルール」参照）
- 「Slackで共有しますか？」とユーザーに確認し、希望があれば `slack:send_message` で投稿
- Slack MCP が利用できない場合はスキップ

## ルール

- 各ステップで処理対象がなければスキップ
- エラーが発生しても次のステップに進む（エラー内容は最後に報告）
- `tmp/` が空なら「tmp は空です」と報告してスキップ
- Slack まとめは best-effort（失敗してもフロー全体は止めない）
- 処理完了後、明日の予定があれば簡単に触れる
- 秘書の口調で報告（`.claude/rules/secretary.md` 参照）
