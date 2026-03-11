# /confluence-create — Confluence ページ作成

Confluence に新しいページを作成するスキル。

## 引数の解釈

| 入力パターン | 動作 |
|-------------|------|
| `/confluence-create` | 対話形式でスペース・タイトル・本文を聞く |
| `/confluence-create "<タイトル>"` | デフォルトスペースにページ作成（本文を聞く） |
| `/confluence-create <spaceKey> "<タイトル>"` | 指定スペースにページ作成（本文を聞く） |

## 実行手順

### 1. スペース確認

- `knowledge/me.md` の Confluence セクションからメインスペース・スペースIDを取得
- 引数でスペースキーが指定されていればそちらを優先
- スペースIDが不明な場合は `./scripts/confluence.sh spaces` で一覧取得して特定

### 2. タイトル確認

- 引数にあればそれを使う
- なければユーザーに聞く

### 3. 本文作成

- ユーザーから本文を受け取る（Markdown で OK）
- Markdown → Atlassian Storage Format (XHTML) に変換:
  - `# 見出し` → `<h1>見出し</h1>`
  - `## 見出し` → `<h2>見出し</h2>`
  - `### 見出し` → `<h3>見出し</h3>`
  - `**太字**` → `<strong>太字</strong>`
  - `*斜体*` → `<em>斜体</em>`
  - `- リスト項目` → `<ul><li>リスト項目</li></ul>`
  - `1. リスト項目` → `<ol><li>リスト項目</li></ol>`
  - `| 表 |` → `<table><tbody><tr><th>...</th></tr><tr><td>...</td></tr></tbody></table>`
  - 空行 → 段落区切り `<p>...</p>`
  - コードブロック → `<ac:structured-macro ac:name="code"><ac:plain-text-body><![CDATA[...]]></ac:plain-text-body></ac:structured-macro>`

### 4. 親ページ（任意）

- ユーザーが親ページを指定した場合、そのページIDを使う
- タイトルで指定された場合は `page-by-title` で ID を解決

### 5. 確認

以下をユーザーに表示して確認を取る:

```
以下の内容でページを作成します。よろしいですか？

- スペース: DEV (ID: 65540)
- タイトル: ○○○
- 親ページ: ○○○ (ID: 12345678)（※指定がある場合）
- 本文プレビュー:
  （最初の数行を表示）
```

### 6. 作成実行

- 確認後に `./scripts/confluence.sh create <spaceId> "<title>" "<body>" [parentId]` を実行
- 成功したら作成されたページの URL を表示

## 他スキルからの呼び出し

| 呼び出し元 | シーン |
|------------|--------|
| `/format-meeting` | 整形済み議事録をConfluenceに投稿 |
| `/brainstorm` | 壁打ち結果をConfluenceにまとめ |
| `/generate-weekly` | 週次サマリーをConfluenceに投稿 |
| `/secretary` | 「Confluenceにページ作って」 |

呼び出し元から本文が渡された場合は、手順3（本文作成）をスキップしてそのまま使う。

## エラー時

`.claude/rules/confluence.md` のエラー対応に従う。

## 注意

- **作成前に必ずユーザーに確認する**（確認なしで作成しない）
- 本文が空の場合でもページ作成は可能（後から `/confluence-update` で追記）
