---
paths:
  - "inbox/tasks/**"
---

# タスクフォーマットルール

`inbox/tasks/` に手動でタスクを追加する際のフォーマット。
議事録からの自動抽出は廃止（議事録内の `## TODO` セクションが正式な記録場所）。

## フォーマット

```markdown
# タスク一覧（YYYY-MM-DD）

- [ ] タスク内容（担当: XX, 期限: MM/DD）
- [ ] タスク内容（担当: 要確認, 期限: 要確認）
```

## ルール

- 担当者・期限が不明な場合は「要確認」と記載
- `knowledge/people.md` を参照して担当者名を統一
- 出力先: `inbox/tasks/YYYY-MM-DD_tasks.md`
