# /jira-check

Jira チケットの状況を確認し、daily/weekly に書き込む。引数でモードを切り替える。

## 引数

- `$ARGUMENTS` でモードを指定。省略時は `morning`。
  - `morning` — オープンチケット一覧 + 前日更新（朝のチェック用）
  - `evening` — 今日更新されたチケット + ステータス変更提案（夕方まとめ用）
  - `daily` — daily に書き込む Jira セクション生成（/generate-daily 用）
  - `weekly` — 今週の完了・新規・進行中を集計（/generate-weekly 用）
  - `overdue` — 期限切れチケット一覧

## 利用可能チェック

実行前に `./scripts/jira.sh myself` で接続確認する。
失敗した場合は「Jira: 取得できませんでした」と報告してスキップ。

## モード別の動作

### morning（デフォルト）

**実行する JQL:**
- オープンチケット: `assignee = currentUser() AND resolution = Unresolved ORDER BY priority DESC`
- 前日更新: `assignee = currentUser() AND updated >= startOfDay("-1d") ORDER BY updated DESC`

**出力:**
```
### Jira チケット
- オープンチケット: X件
- 昨日更新されたもの: PROJ-123 ステータス変更あり
```

**daily 更新:** `daily/YYYY-MM-DD.md` の TODO セクションを Jira + ローカルの統合ビューとして更新する。

### evening

**実行する JQL:**
- 今日更新: `assignee = currentUser() AND updated >= startOfDay() ORDER BY updated DESC`
- オープン: `assignee = currentUser() AND resolution = Unresolved ORDER BY priority DESC`

**出力:**
```
### Jira
- 担当チケット: X件（うち今日更新: X件）
- ステータス変更の提案: PROJ-123 → Done にしますか？
```

**追加アクション:**
- 今日のMTGや作業に関連するチケットのステータス変更を提案
- ステータス変更はユーザー確認後に `/jira-update-ticket` で実行
- `daily/YYYY-MM-DD.md` の TODO セクションを統合ビューとして最終更新

### daily

**実行する JQL:**
- オープンチケット: `assignee = currentUser() AND resolution = Unresolved ORDER BY priority DESC`
- 今日完了: `assignee = currentUser() AND status changed to Done AFTER startOfDay() ORDER BY updated DESC`

**出力:** Jira チケットを取得し、`daily/YYYY-MM-DD.md` の TODO セクションにローカルタスクと統合して表示する。
独立した `## Jira` セクションは作らない（`.claude/rules/tasks.md` の統合ビュー参照）。

### weekly

**実行する JQL:**
- 今週完了: `assignee = currentUser() AND status changed to Done AFTER startOfWeek() ORDER BY updated DESC`
- 今週新規: `assignee = currentUser() AND created >= startOfWeek() ORDER BY created DESC`
- 進行中: `assignee = currentUser() AND resolution = Unresolved ORDER BY priority DESC`

**出力フォーマット（weekly に書き込む形式）:**
```markdown
## Jira サマリー
- チケット完了: X件
- チケット新規: X件
- 進行中: X件
```

### overdue

**実行する JQL:**
- `assignee = currentUser() AND duedate < now() AND resolution = Unresolved ORDER BY duedate ASC`

**出力:**
期限切れチケットの一覧をテーブル形式で表示。

## 共通ルール

- `knowledge/me.md` の Jira セクションにメインプロジェクトの設定があれば `AND project = <KEY>` を追加
- `.claude/rules/jira.md` のルールに従う
- `.claude/rules/tasks.md` の統合ビュールールに従って daily の TODO セクションを更新
- `scripts/jira.sh` が失敗した場合はスキップ（フロー全体は止めない）
- 秘書から呼ばれた場合は秘書の口調で報告

## 呼び出し元

| スキル | モード |
|--------|--------|
| `/morning` | `morning` |
| `/evening` | `evening` |
| `/generate-daily` | `daily` |
| `/generate-weekly` | `weekly` |
| `/secretary`（ダッシュボード） | `daily` |
| `/secretary`（チケット確認） | `morning` or 引数なし |
