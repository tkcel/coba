# /jira-create-ticket

Jira にチケットを起票する。対話形式で必要な情報を確認してから作成する。

## 引数

- `$ARGUMENTS` にタイトルや概要を指定できる。省略時はヒアリングから開始。

## 利用可能チェック

実行前に `./scripts/jira.sh myself` で接続確認する。
失敗した場合はセットアップ手順を案内して終了（`scripts/README.md` 参照）。

## フロー

### 1. 情報収集

以下をユーザーに確認する（引数から推測できるものはデフォルト値として提示）:

| 項目 | 必須 | デフォルト | 確認方法 |
|------|:----:|-----------|----------|
| プロジェクト | ○ | `knowledge/me.md` のメインプロジェクト | なければ `./scripts/jira.sh projects` で一覧表示して選択 |
| 課題タイプ | ○ | Task | Task / Bug / Story / Epic から選択 |
| タイトル | ○ | `$ARGUMENTS` から取得 | なければヒアリング |
| 説明 | | なし | 任意。あれば追加 |
| 親Epic | ○ | なし | `./scripts/jira.sh search "project = <KEY> AND issuetype = エピック"` で一覧表示して選択 |
| 担当者 | ○ | `knowledge/me.md` のオーナー | 他の人の場合は `./scripts/jira.sh users "<名前>"` で検索 |
| 期限 | ○ | なし | 日付を確認 |
| スプリント | ○ | **進行中スプリント** | Agile API で active sprint を取得して自動設定 |

### 2. 確認

```
以下の内容でチケットを作成します。よろしいですか？

| 項目 | 値 |
|------|-----|
| プロジェクト | PROJ |
| タイプ | Task |
| 親Epic | PROJ-39 (other) |
| タイトル | ○○の対応 |
| 説明 | △△のため対応が必要 |
| 担当者 | 山田 太郎 |
| 期限 | 2026-03-20 |
| スプリント | DEVALL スプリント 1（進行中） |
```

### 3. 作成

`jira.sh create` は親Epic・担当者・期限・スプリントに未対応のため、REST API を直接呼び出す。

```bash
# 認証情報読み込み
source "$HOME/.config/jira/credentials"
AUTH=$(printf '%s:%s' "$JIRA_EMAIL" "$JIRA_API_TOKEN" | base64)

# チケット作成（parent, assignee, duedate 含む）
curl -s -X POST \
  -H "Authorization: Basic $AUTH" \
  -H "Content-Type: application/json" \
  -d '{
    "fields": {
      "project": { "key": "PROJ" },
      "issuetype": { "name": "タスク" },
      "parent": { "key": "PROJ-39" },
      "summary": "○○の対応",
      "description": { ... },
      "assignee": { "accountId": "..." },
      "duedate": "2026-03-20"
    }
  }' \
  "https://${JIRA_DOMAIN}/rest/api/3/issue"
```

### 3b. スプリントに追加

進行中スプリントに追加する（デフォルト動作）。

```bash
# 進行中スプリントID を取得
# ボードID は knowledge/me.md や memory から取得。DEV の場合は 34
curl -s -H "Authorization: Basic $AUTH" \
  "https://${JIRA_DOMAIN}/rest/agile/1.0/board/{boardId}/sprint?state=active" | jq '.values[0].id'

# スプリントに追加
curl -s -X POST \
  -H "Authorization: Basic $AUTH" \
  -H "Content-Type: application/json" \
  -d '{ "issues": ["PROJ-789"] }' \
  "https://${JIRA_DOMAIN}/rest/agile/1.0/sprint/{sprintId}/issue"
```

### 4. 報告

```
チケットを作成しました！

PROJ-789: ○○の対応
https://{domain}.atlassian.net/browse/PROJ-789

| 項目 | 値 |
|------|-----|
| 親Epic | PROJ-39 (other) |
| 担当者 | 山田 太郎 |
| 期限 | 2026-03-20 |
| スプリント | DEVALL スプリント 1（進行中） |
```

`knowledge/me.md` の Jira セクションからドメインを取得して URL を組み立てる。

### 5. ダッシュボード更新

チケット作成後、**必ず** 当日の `daily/YYYY-MM-DD.md` の TODO セクションに新チケットを追加する。

- 担当者が自分の場合 → `🔲 未着手` セクションに追加
- ファイルが存在しない場合 → `/generate-daily` の実行を提案

## 一括起票

`/extract-todo` から呼ばれた場合、抽出された TODO リストを元に複数チケットの起票を提案できる。

**フロー:**
1. 抽出された TODO を一覧表示
2. 「Jira にチケットを作成しますか？」と確認
3. 作成対象を選択（全部 / 個別選択）
4. 各チケットを順番に作成
5. 結果をまとめて報告

## ルール

- **作成前に必ずユーザーに確認する**（確認なしで作成しない）
- `.claude/rules/jira.md` のルールに従う
- プロジェクトキーが不明な場合は `./scripts/jira.sh projects` で確認
- `scripts/jira.sh` が失敗した場合はエラーメッセージを表示
- 秘書から呼ばれた場合は秘書の口調で対話

## 呼び出し元

| スキル | 状況 |
|--------|------|
| `/secretary` | 「チケット作って」「起票して」 |
| `/extract-todo` | TODO 抽出後の Jira 起票オプション |
