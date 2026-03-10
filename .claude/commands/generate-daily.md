# /generate-daily

Google Calendar から今日（または指定日）の予定を取得し、日次アジェンダを生成する。

## 引数

- `$ARGUMENTS` - 対象日（省略時は今日）。例: `2024-03-15`, `tomorrow`, `monday`

## 出力先

`daily/YYYY-MM-DD.md`

## 出力フォーマット

```markdown
# YYYY-MM-DD（曜日）

## スケジュール

| 時間 | 予定 | 種別 | 人数 |
|------|------|------|------|
| 09:00-09:30 | 朝礼 | 全体朝礼 | 20名 |
| 10:00-11:00 | 開発定例 | 定例MTG | 7名 |

## MTG メモ欄

### 09:00 朝礼
-

### 10:00 開発定例
- 📎 https://...（カレンダーのdescriptionから）
-

## 作業ブロック
- 13:00-17:00 集中作業
  - [ ]

## 持ち越し TODO
- [ ] ...（前日・inbox/tasks/ から）
```

## MTG 分類ルール

`.claude/rules/daily.md` の「MTG 分類ルール」セクションを参照。

- デフォルトルール + カスタムルールの両方を適用
- カスタムルールは `/onboarding` または `/optimize-rules` で追加

## ルール

- eventType が `outOfOffice` → 「作業ブロック」セクションに分離
- description にURLがあれば 📎 付きで記載
- 既に同日のファイルがある場合は上書きせず確認
- `inbox/tasks/` に未完了タスクがあれば「持ち越し TODO」に記載
