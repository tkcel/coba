# /jira-check

Jira チケットの状況を確認する。引数でモードを切り替え、各スキルから呼び出される。

## 引数

- `$ARGUMENTS` - モード指定（省略時は `my-tickets`）

| モード | 説明 | 呼び出し元 |
|--------|------|-----------|
| `my-tickets` | 自分のオープンチケット一覧 | `/secretary`, `/morning` |
| `overdue` | 期限切れチケット | `/morning`, `/secretary` |
| `today` | 今日更新されたチケット | `/evening`, `/generate-daily` |
| `daily` | daily 用 Jira セクション生成 | `/generate-daily` |
| `weekly` | 週次 Jira サマリー生成 | `/generate-weekly` |

## 前提確認

1. `scripts/jira.sh` が存在するか確認
2. `~/.config/jira/credentials` が存在するか確認
3. いずれかがなければ「Jira: 未設定です。`/onboarding` で設定できます」と返して終了

## モード別の動作

### `my-tickets`（デフォルト）

```bash
./scripts/jira.sh search "assignee = currentUser() AND resolution = Unresolved ORDER BY priority DESC"
```

**出力フォーマット:**

```markdown
### オープンチケット（X件）
| キー | タイトル | ステータス | 優先度 | 期限 |
|------|---------|----------|--------|------|
| PROJ-123 | ○○の実装 | In Progress | High | 03/15 |
| PROJ-456 | △△の修正 | To Do | Medium | 03/20 |
```

チケットがない場合: 「オープンチケットはありません」

### `overdue`

```bash
./scripts/jira.sh search "assignee = currentUser() AND duedate < now() AND resolution = Unresolved ORDER BY duedate ASC"
```

**出力フォーマット:**

```markdown
### ⚠️ 期限超過チケット（X件）
| キー | タイトル | 期限 | 超過日数 |
|------|---------|------|---------|
| PROJ-456 | △△の修正 | 03/08 | 3日 |
```

チケットがない場合: 「期限超過チケットはありません」

### `today`

```bash
./scripts/jira.sh search "assignee = currentUser() AND updated >= startOfDay() ORDER BY updated DESC"
```

**出力フォーマット:**

```markdown
### 今日更新されたチケット（X件）
| キー | タイトル | ステータス | 更新日時 |
|------|---------|----------|---------|
| PROJ-123 | ○○の実装 | Done | 15:30 |
| PROJ-789 | ××の調査 | In Progress | 10:00 |
```

チケットがない場合: 「今日更新されたチケットはありません」

### `daily`

`my-tickets` + `today` を組み合わせて、daily 用の Jira セクションを生成。

**出力フォーマット:**

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

### `weekly`

```bash
# 今週完了
./scripts/jira.sh search "assignee = currentUser() AND status changed to Done AFTER startOfWeek()"
# 期限超過
./scripts/jira.sh search "assignee = currentUser() AND duedate < now() AND resolution = Unresolved"
```

**出力フォーマット:**

```markdown
## Jira サマリー
- 今週完了: XX件
- オーバーデュー: XX件

### 完了チケット
| キー | タイトル | 完了日 |
|------|---------|--------|
| PROJ-123 | ○○の実装 | 03/10 |

### オーバーデュー
| キー | タイトル | 期限 |
|------|---------|------|
| PROJ-456 | △△の修正 | 03/08 |
```

## エラー時の動作

- API エラー: 「Jira: 取得できませんでした」と出力してスキップ
- 認証エラー (exit code 1): 「Jira: 認証エラーです。APIトークンを確認してください」
- エラーが発生しても呼び出し元のスキルの実行は止めない

## ルール

- `.claude/rules/jira.md` のフォーマットに従う
- 秘書から呼ばれた場合は秘書の口調で報告
- 他スキルから呼ばれた場合はそのまま Markdown を返す
