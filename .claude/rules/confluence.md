# Confluence 連携ルール

Confluence Cloud REST API を `scripts/confluence.sh` 経由で操作する際のルール。

## スクリプトの使い方

```bash
# スペース一覧
./scripts/confluence.sh spaces

# CQL 検索
./scripts/confluence.sh search "type = page AND space = DEV AND text ~ 'リリース'"

# ページ詳細（IDで）
./scripts/confluence.sh page 12345678

# ページ詳細（タイトルで）
./scripts/confluence.sh page-by-title DEV "開発ガイドライン"

# 子ページ一覧
./scripts/confluence.sh children 12345678

# ページ作成（親ページなし）
./scripts/confluence.sh create 65540 "議事録 2026-03-11" "<p>本文</p>"

# ページ作成（親ページあり）
./scripts/confluence.sh create 65540 "議事録 2026-03-11" "<p>本文</p>" 12345678

# ページ更新
./scripts/confluence.sh update 12345678 "更新後タイトル" "<p>更新後本文</p>"

# コメント追加
./scripts/confluence.sh comment 12345678 "確認しました"

# コメント一覧
./scripts/confluence.sh comments 12345678
```

## よく使う CQL

| 用途 | CQL |
|------|-----|
| スペース内全ページ | `type = page AND space = <KEY>` |
| キーワード検索 | `type = page AND text ~ '<keyword>'` |
| タイトル検索 | `type = page AND title ~ '<keyword>'` |
| 自分が作成 | `type = page AND creator = currentUser()` |
| 最近更新（直近7日） | `type = page AND lastModified >= now('-7d') ORDER BY lastModified DESC` |
| スペース + キーワード | `type = page AND space = <KEY> AND text ~ '<keyword>'` |

`knowledge/me.md` の Confluence セクションにデフォルトスペースの設定があればそれを使う。

## 破壊的操作の確認

以下の操作は必ずユーザーに確認してから実行する:

- ページ作成（`create`）
- ページ更新（`update`）
- コメント追加（`comment`）

検索・閲覧系（`spaces`, `search`, `page`, `page-by-title`, `children`, `comments`）は確認不要。

## 本文フォーマット

- スクリプトは Atlassian Storage Format (XHTML) で入出力する
- Markdown → Storage Format の変換はスキル側で行う
- 簡易変換ルール:
  - `# 見出し` → `<h1>見出し</h1>`
  - `## 見出し` → `<h2>見出し</h2>`
  - `**太字**` → `<strong>太字</strong>`
  - `- リスト` → `<ul><li>リスト</li></ul>`
  - `| 表 |` → `<table>...</table>`
  - 改行 → `<br />`

## エラー時の対応

- 認証エラー（exit 1）→ API トークンの確認を促す
- リソースなし（exit 2）→ ページID・スペースキーの確認を促す
- レート制限（exit 3）→ スクリプトが自動リトライ。それでも失敗したらスキップ
- その他（exit 4）→ エラーメッセージを表示してスキップ
