---
paths:
  - "scripts/jira.sh"
---

# Jira 連携ルール

Jira Cloud REST API との連携ルール。全スキルから参照。

## スクリプトの使い方

Jira 操作は `scripts/jira.sh` を Bash ツールで実行する。

```bash
# 自分の情報
./scripts/jira.sh myself

# JQL検索
./scripts/jira.sh search "assignee = currentUser() AND resolution = Unresolved ORDER BY priority DESC"

# チケット詳細
./scripts/jira.sh issue PROJ-123

# チケット作成
./scripts/jira.sh create PROJ Task "タスクのタイトル" "説明文"

# 遷移先一覧
./scripts/jira.sh transitions PROJ-123

# ステータス変更
./scripts/jira.sh transition PROJ-123 31

# コメント追加
./scripts/jira.sh comment PROJ-123 "コメント本文"

# プロジェクト一覧
./scripts/jira.sh projects

# ユーザー検索
./scripts/jira.sh users "根本"
```

## よく使う JQL

| 用途 | JQL |
|------|-----|
| 自分の未完了チケット | `assignee = currentUser() AND resolution = Unresolved ORDER BY priority DESC` |
| 今日更新されたチケット | `assignee = currentUser() AND updated >= startOfDay() ORDER BY updated DESC` |
| 期限切れチケット | `assignee = currentUser() AND duedate < now() AND resolution = Unresolved` |
| 今週完了したチケット | `assignee = currentUser() AND status changed to Done AFTER startOfWeek()` |
| プロジェクト指定 | 上記に `AND project = <KEY>` を追加 |

## knowledge/me.md の Jira セクション

`knowledge/me.md` の `## Jira` セクションから以下を読み取る:

| 項目 | 用途 |
|------|------|
| ドメイン | 接続先の確認 |
| プロジェクトキー | デフォルトのプロジェクト |
| アカウントID | JQL の `currentUser()` が使えない場合の代替 |

## チケット表示フォーマット

### 一覧表示（search結果）

```markdown
| キー | タイトル | ステータス | 優先度 | 期限 |
|------|---------|----------|--------|------|
| PROJ-123 | ○○の実装 | In Progress | High | 03/15 |
| PROJ-456 | △△の修正 | To Do | Medium | 03/20 |
```

### 詳細表示（issue結果）

```markdown
### PROJ-123: ○○の実装

| 項目 | 値 |
|------|-----|
| ステータス | In Progress |
| 優先度 | High |
| 担当 | 根本 貴志 |
| 期限 | 2026-03-15 |
| 作成日 | 2026-03-01 |
| 更新日 | 2026-03-11 |

**説明:** ○○の実装を行う

**直近のコメント:**
- 山田さん (03/10): ○○について確認しました
```

## daily/ の Jira セクション

`daily/YYYY-MM-DD.md` で `## 作業ブロック` と `## Slack まとめ` の間に配置。

```markdown
## Jira

### オープンチケット
| キー | タイトル | ステータス | 優先度 | 期限 |
|------|---------|----------|--------|------|
| PROJ-123 | ○○の実装 | In Progress | High | 03/15 |

### 今日更新
| キー | タイトル | 変更内容 |
|------|---------|---------|
| PROJ-789 | ××の修正 | Done に変更 |
```

## エラー時のフォールバック

Jira API に接続できない・エラーが発生した場合:

- `daily/` や週次サマリーでは「Jira: 取得できませんでした」と記載してスキップ
- 秘書はエラー内容をユーザーに伝え、代替手段を提案
- スクリプトが見つからない・認証情報がない場合は `/onboarding` の Jira セットアップを案内

## 破壊的操作の確認

以下の操作は **必ずユーザーに確認してから** 実行する:

- チケット作成（`create`）
- ステータス変更（`transition`）
- コメント追加（`comment`）

確認フォーマット例:
```
以下の内容でチケットを作成しますか？

- プロジェクト: PROJ
- タイプ: Task
- タイトル: ○○の実装
- 説明: ○○について...

→ 作成する / キャンセル
```
