# /evening

夕方の一括整理。tmp振り分け → 議事録整形 → TODO抽出 を連続実行する。

## 実行フロー

```
1. tmp/ のファイル確認
      ↓
2. [/triage-tmp] tmp → inbox 振り分け
      ↓
3. [/format-meeting] inbox/meetings/ の未整形ファイルを整形
      ↓
4. [/extract-todo] 整形済み議事録からTODO抽出
      ↓
5. サマリー報告
      ↓
6. 週末（金〜日）なら [/generate-weekly]
```

## サマリー報告フォーマット

```
## 夕方まとめ完了

### 振り分け結果
- meetings: X件
- tasks: X件
- notes: X件
- other: X件

### 整形した議事録
- YYYY-MM-DD_会議名.md
- ...

### 抽出したTODO
- [ ] タスク内容（担当: XX）
- [ ] ...
```

## 週末バリエーション（金・土・日）

週末に実行した場合は、上記に加えて `/generate-weekly` も実行する。

```
### 週次サマリー
weekly/YYYY-Www.md を生成しました。

今週の振り返り:
- MTG参加数: XX件
- タスク完了: XX件
```

## ルール

- 各ステップで処理対象がなければスキップ
- エラーが発生しても次のステップに進む（エラー内容は最後に報告）
- `tmp/` が空なら「tmp は空です」と報告してスキップ
- 処理完了後、明日の予定があれば簡単に触れる
- 秘書の口調で報告（`.claude/rules/secretary.md` 参照）
