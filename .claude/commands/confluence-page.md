# /confluence-page — Confluence ページ閲覧・検索

閲覧・検索専用スキル。ページの変更・作成は行わない。

## 引数の解釈

| 入力パターン | 動作 |
|-------------|------|
| `/confluence-page <数字>` | ページID → `page` コマンドで詳細表示 |
| `/confluence-page search <キーワード>` | CQL でキーワード検索 |
| `/confluence-page CQL <CQL>` | CQL 直接実行 |
| `/confluence-page spaces` | スペース一覧表示 |
| `/confluence-page children <数字>` | 子ページ一覧表示 |
| `/confluence-page title <spaceKey> <タイトル>` | タイトルでページ検索 |
| 引数なし | 使い方を案内 |

## 実行手順

### ページ詳細表示

1. `./scripts/confluence.sh page <pageId>` を実行
2. 結果を整形して表示:
   - タイトル、スペース、バージョン、最終更新日、URL
   - 本文は Storage Format からテキストを抽出して読みやすく表示
3. 「このページを更新する場合は `/confluence-update <pageId>` を使ってください」と案内

### キーワード検索

1. デフォルトスペースを `knowledge/me.md` の Confluence セクションから取得
2. CQL を組み立て: `type = page AND text ~ '<keyword>'`
   - デフォルトスペースがあれば `AND space = <KEY>` を追加
3. `./scripts/confluence.sh search "<CQL>"` を実行
4. 結果を一覧表示（タイトル、スペース、最終更新日、URL）

### CQL 直接実行

1. `./scripts/confluence.sh search "<CQL>"` を実行
2. 結果を一覧表示

### スペース一覧

1. `./scripts/confluence.sh spaces` を実行
2. ID、キー、名前を一覧表示

### 子ページ一覧

1. `./scripts/confluence.sh children <pageId>` を実行
2. ID、タイトルを一覧表示

### タイトル検索

1. `./scripts/confluence.sh page-by-title <spaceKey> "<title>"` を実行
2. 結果を表示

## 出力フォーマット

### ページ詳細

```markdown
## <タイトル>

| 項目 | 値 |
|------|-----|
| ID | 12345678 |
| スペース | DEV |
| バージョン | 5 |
| 最終更新 | 2026-03-10 |
| URL | https://... |

### 本文

（本文のテキスト内容）
```

### 検索結果

```markdown
## 検索結果（N件）

| # | タイトル | スペース | 更新日 | ID |
|---|---------|---------|--------|-----|
| 1 | ページA | DEV | 2026-03-10 | 123 |
| 2 | ページB | DEV | 2026-03-09 | 456 |
```

## エラー時

`.claude/rules/confluence.md` のエラー対応に従う。

## 注意

- このスキルは**閲覧専用**。ページの作成・更新・コメント追加は行わない
- 作成は `/confluence-create`、更新は `/confluence-update` を案内する
