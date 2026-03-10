# /format-meeting

指定された会議メモ、または inbox/meetings/ 内の未整形ファイルを構造化された議事録に整形する。

## 引数

- `$ARGUMENTS` - 整形対象のファイルパス（省略時は inbox/meetings/ 内の未整形ファイルを対象）

## 出力フォーマット

```markdown
# [会議名] YYYY-MM-DD

- 日時: YYYY-MM-DD HH:MM〜HH:MM
- 参加者: （不明なら「要確認」）
- 種別: 定例MTG / 1on1 / 開発系MTG / 外部MTG / その他

## アジェンダ
1. ...

## 議論の要約
### [トピック名]
- ...

## 決定事項
- ○○を実施する（担当: XX, 期限: MM/DD）

## TODO
- [ ] ○○（担当: XX, 期限: MM/DD）

## 備考
- ...
```

## 補完ルール

- `knowledge/people.md` を参照して人名を正式名称に統一
- `knowledge/glossary.md` を参照して略称を展開
- Google Calendar の予定情報が使えるなら、会議名・日時・参加者を補完

## 注意

- 情報が足りない項目は「要確認」と記載。**推測で埋めない**
- 整形後は元のファイルを上書き
