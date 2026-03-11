# /jira-update-ticket

Jira チケットのステータス変更・コメント追加を行う。

## 引数

- `$ARGUMENTS` - チケットキーと操作（例: `PROJ-123 done`, `PROJ-123 comment 確認しました`）

## 前提確認

1. `scripts/jira.sh` が存在するか確認
2. `~/.config/jira/credentials` が存在するか確認
3. いずれかがなければ「Jira: 未設定です。`/onboarding` で設定できます」と返して終了

## 操作パターン

### ステータス変更

引数例: `PROJ-123 done`, `PROJ-123 進行中`, `PROJ-123`（操作未指定）

**フロー:**

1. チケットの現在情報を取得
   ```bash
   ./scripts/jira.sh issue PROJ-123
   ```

2. 遷移先一覧を取得
   ```bash
   ./scripts/jira.sh transitions PROJ-123
   ```

3. 操作が指定されている場合はマッチする遷移を探す
   - `done` / `完了` → "Done" への遷移
   - `進行中` / `in progress` → "In Progress" への遷移
   - マッチしなければ一覧から選択

4. 操作が未指定の場合は遷移先を一覧表示して選択
   ```
   PROJ-123: ○○の実装（現在: In Progress）

   遷移先:
   1. Done
   2. To Do
   3. In Review

   → 番号を選択 / キャンセル
   ```

5. **確認してから実行**
   ```
   PROJ-123 を「Done」に変更します。よろしいですか？
   → 変更する / キャンセル
   ```

6. 実行
   ```bash
   ./scripts/jira.sh transition PROJ-123 <transitionId>
   ```

7. 結果報告
   ```
   ✅ PROJ-123: ○○の実装 → Done に変更しました
   ```

### コメント追加

引数例: `PROJ-123 comment 確認しました`

**フロー:**

1. コメント内容の確認
   ```
   PROJ-123 に以下のコメントを追加します。

   > 確認しました

   → 追加する / 修正する / キャンセル
   ```

2. 実行
   ```bash
   ./scripts/jira.sh comment PROJ-123 "確認しました"
   ```

3. 結果報告
   ```
   💬 PROJ-123 にコメントを追加しました
   ```

## `/evening` からの呼び出し

`/evening` の Jira チケット状況確認で呼ばれる場合:

- 今日更新されたチケットの中で、ステータス変更が必要そうなものを提案
- 例:「PROJ-123（In Progress）、今日作業しましたか？ Done にしますか？」
- ユーザーが承認したものだけ変更

```
今日更新されたチケットのステータス確認:

🎫 PROJ-123: ○○の実装（In Progress）
→ Done にしますか？ [はい / いいえ / スキップ]

🎫 PROJ-456: △△の調査（To Do）
→ In Progress にしますか？ [はい / いいえ / スキップ]
```

## エラー時の動作

- チケットが見つからない (exit code 2): 「チケットが見つかりません。キーを確認してください」
- 遷移できない: 「この遷移は現在のステータスからは実行できません」
- API エラー: エラー内容を表示

## ルール

- **ステータス変更・コメント追加は必ずユーザー確認後に実行する**
- `.claude/rules/jira.md` のフォーマットに従う
- 変更後、`inbox/tasks/current.md` に対応するタスクがあればステータス同期を提案
