# Jira 連携ルール

Jira Cloud REST API を `scripts/jira.sh` 経由で操作する際のルール。

## スクリプトの使い方

```bash
# 自分の情報
./scripts/jira.sh myself

# チケット検索（JQL）
./scripts/jira.sh search "assignee = currentUser() AND resolution = Unresolved ORDER BY priority DESC"

# チケット詳細
./scripts/jira.sh issue PROJ-123

# チケット作成
./scripts/jira.sh create PROJ Task "タイトル" "説明（任意）"

# 遷移先一覧
./scripts/jira.sh transitions PROJ-123

# ステータス変更
./scripts/jira.sh transition PROJ-123 31

# コメント追加
./scripts/jira.sh comment PROJ-123 "コメント本文"

# プロジェクト一覧
./scripts/jira.sh projects

# ユーザー検索
./scripts/jira.sh users "山田"
```

## よく使う JQL

| 用途 | JQL |
|------|-----|
| 自分の未完了チケット | `assignee = currentUser() AND resolution = Unresolved ORDER BY priority DESC` |
| 今日更新されたチケット | `assignee = currentUser() AND updated >= startOfDay() ORDER BY updated DESC` |
| 期限切れチケット | `assignee = currentUser() AND duedate < now() AND resolution = Unresolved` |
| 今週完了 | `assignee = currentUser() AND status changed to Done AFTER startOfWeek()` |
| プロジェクト絞り込み | 上記に `AND project = <KEY>` を追加 |

`knowledge/me.md` の Jira セクションにデフォルト JQL やプロジェクトキーの設定があればそれを使う。

## daily/ での Jira 表示

Jira チケットは `daily/` の独立セクション（`## Jira`）ではなく、**TODO セクションに統合** して表示する。
詳細は `.claude/rules/tasks.md` の「統合 TODO ダッシュボード」を参照。

- `ソース` 列にチケットキー（`DEV-64` 等）を表示
- ステータスはローカルのステータス体系にマッピング（`.claude/rules/tasks.md` 参照）
- ダッシュボード表示・更新時に Jira を API 取得して最新化する
- Jira 取得できなかった場合はローカルタスクのみ表示し「Jira: 取得できませんでした」と注記

## 破壊的操作の確認

以下の操作は必ずユーザーに確認してから実行する:

- チケット作成（`create`）
- ステータス変更（`transition`）
- コメント追加（`comment`）

検索・閲覧系（`search`, `issue`, `transitions`, `projects`, `users`, `myself`）は確認不要。

## エラー時の対応

- 認証エラー（exit 1）→ API トークンの確認を促す
- リソースなし（exit 2）→ チケットキーの確認を促す
- レート制限（exit 3）→ スクリプトが自動リトライ。それでも失敗したらスキップ
- その他（exit 4）→ エラーメッセージを表示してスキップ

## COBA タスク管理との連携

- Jira とローカル（`inbox/tasks/current.md`）は **別々のマスター** として管理
- `daily/` の TODO セクションで統合ビューとして1つのテーブルに表示
- Jira → ローカルへのコピーや自動同期はしない
- ローカルタスクを Jira に起票したい場合は `/jira-create-ticket` を使う
