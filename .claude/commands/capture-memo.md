# /capture-memo

クイックメモを `tmp/` にキャプチャする。

## 引数

- `$ARGUMENTS` - メモの内容

## 出力先

`tmp/memo_YYYY-MM-DD_HHMMSS.md`

## 出力フォーマット

```markdown
# メモ - YYYY-MM-DD HH:MM

[ユーザーの入力内容]

---
captured by /capture-memo
```

## ルール

- タイムスタンプ付きでファイル名を生成
- 内容はそのまま記録（整形しない）
- 完了後「メモを保存しました: [ファイル名]」と報告
- 後で `/triage-tmp` で振り分けることを提案
