# /confluence-update — Confluence ページ更新・コメント追加

既存の Confluence ページの更新・コメント追加を行うスキル。

## 引数の解釈

| 入力パターン | 動作 |
|-------------|------|
| `/confluence-update <pageId> 追記 <テキスト>` | 既存本文の末尾に追記 |
| `/confluence-update <pageId> 上書き <テキスト>` | 本文全体を置換 |
| `/confluence-update <pageId> コメント <テキスト>` | フッターコメント追加 |
| `/confluence-update <pageId>` | 何をしたいか聞く |

## 実行手順

### 追記モード

1. `./scripts/confluence.sh page <pageId>` で現在のページを取得
2. 現在の本文（Storage Format）の末尾に、新しいコンテンツを追加
   - ユーザーの入力を Markdown → Storage Format に変換
3. 変更内容をプレビュー表示:
   ```
   ページ「○○○」に以下を追記します:

   （追記内容のプレビュー）

   よろしいですか？
   ```
4. **ユーザーの確認後** に `./scripts/confluence.sh update <pageId> "<title>" "<newBody>"` を実行
5. 更新結果（バージョン番号、URL）を表示

### 上書きモード

1. `./scripts/confluence.sh page <pageId>` で現在のページを取得
2. 現在のタイトルを保持（タイトル変更が指定されていれば新タイトルを使用）
3. 新しい本文を Markdown → Storage Format に変換
4. 変更内容をプレビュー表示:
   ```
   ページ「○○○」の本文を上書きします。

   【現在の本文】
   （最初の数行）

   【新しい本文】
   （最初の数行）

   よろしいですか？
   ```
5. **ユーザーの確認後** に `./scripts/confluence.sh update <pageId> "<title>" "<newBody>"` を実行
6. 更新結果を表示

### コメントモード

1. コメント内容を確認表示:
   ```
   ページ (ID: <pageId>) に以下のコメントを追加します:

   「○○○」

   よろしいですか？
   ```
2. **ユーザーの確認後** に `./scripts/confluence.sh comment <pageId> "<body>"` を実行
3. 結果を表示

## Markdown → Storage Format 変換

`/confluence-create` と同じ変換ルールに従う。

## 他スキルからの呼び出し

| 呼び出し元 | シーン |
|------------|--------|
| `/secretary` | 「Confluenceのページを更新して」 |

## エラー時

`.claude/rules/confluence.md` のエラー対応に従う。

## 注意

- **更新・コメント追加は必ずユーザーに確認してから実行する**（確認なしで実行しない）
- 更新時はバージョン番号を自動インクリメントする（スクリプト側で処理済み）
- 追記モードでは既存の本文を壊さない（末尾に追加するのみ）
