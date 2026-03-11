# scripts/

COBA ワークスペースで使うスクリプト群。

## jira.sh - Jira Cloud REST API ラッパー

Jira Cloud の REST API v3 を curl で呼び出すシェルスクリプト。
Claude Code の Bash ツールから直接実行して使う。

### セットアップ

#### 1. Jira API トークンを発行

1. https://id.atlassian.com/manage-profile/security/api-tokens にアクセス
2. 「API トークンを作成」をクリック
3. ラベル（例: `coba-workspace`）を入力して作成
4. 表示されたトークンをコピー（この画面を閉じると二度と表示されない）

#### 2. 認証情報ファイルを作成

```bash
# ディレクトリ作成
mkdir -p ~/.config/jira

# 認証情報ファイルを作成（各値を自分のものに置き換える）
cat > ~/.config/jira/credentials << 'EOF'
JIRA_DOMAIN=your-domain.atlassian.net
JIRA_EMAIL=your-email@example.com
JIRA_API_TOKEN=your-api-token-here
EOF

# パーミッション設定（重要: 自分だけ読み書き可能に）
chmod 600 ~/.config/jira/credentials
```

| 変数 | 説明 | 例 |
|------|------|-----|
| `JIRA_DOMAIN` | Jira Cloud のドメイン | `your-company.atlassian.net` |
| `JIRA_EMAIL` | Atlassian アカウントのメールアドレス | `you@example.com` |
| `JIRA_API_TOKEN` | 手順1で発行した API トークン | `ATATT3x...` |

#### 3. 接続テスト

```bash
./scripts/jira.sh myself
```

成功すると自分のアカウント情報が JSON で返る:

```json
{
  "accountId": "xxxxx",
  "displayName": "あなたの名前",
  "emailAddress": "you@example.com",
  "active": true
}
```

#### 4. knowledge/me.md に Jira 設定を追記

接続テストが成功したら、`knowledge/me.md` に以下を追加する:

```markdown
## Jira

| 項目 | 値 |
|------|-----|
| ドメイン | your-domain.atlassian.net |
| メインプロジェクト | PROJ |
| アカウントID | （myself の結果からコピー） |
```

メインプロジェクトは `./scripts/jira.sh projects` で一覧を確認して選ぶ。

### 使い方

#### 自分の情報を取得

```bash
./scripts/jira.sh myself
```

#### チケット検索（JQL）

```bash
# 自分の未完了チケット
./scripts/jira.sh search "assignee = currentUser() AND resolution = Unresolved ORDER BY priority DESC"

# 今日更新されたチケット
./scripts/jira.sh search "assignee = currentUser() AND updated >= startOfDay() ORDER BY updated DESC"

# 期限切れチケット
./scripts/jira.sh search "assignee = currentUser() AND duedate < now() AND resolution = Unresolved"

# プロジェクト指定
./scripts/jira.sh search "project = PROJ AND resolution = Unresolved ORDER BY priority DESC"

# 件数指定（デフォルト50件）
./scripts/jira.sh search "assignee = currentUser() AND resolution = Unresolved" 10
```

#### チケット詳細

```bash
./scripts/jira.sh issue PROJ-123
```

#### チケット作成

```bash
# 説明なし
./scripts/jira.sh create PROJ Task "○○の対応"

# 説明あり
./scripts/jira.sh create PROJ Task "○○の対応" "詳細な説明文"

# Bug タイプ
./scripts/jira.sh create PROJ Bug "○○が動かない" "再現手順: ..."
```

#### ステータス変更

```bash
# まず遷移先を確認
./scripts/jira.sh transitions PROJ-123
# 出力例: [{"id": "31", "name": "Done", "to": "Done"}, ...]

# 遷移を実行
./scripts/jira.sh transition PROJ-123 31
```

#### コメント追加

```bash
./scripts/jira.sh comment PROJ-123 "確認しました。問題ありません。"
```

#### プロジェクト一覧

```bash
./scripts/jira.sh projects
```

#### ユーザー検索

```bash
./scripts/jira.sh users "山田"
```

### 出力形式

すべてのコマンドは JSON で出力する。`jq` で整形済み。

### エラーハンドリング

| Exit Code | 意味 | 対処 |
|-----------|------|------|
| 0 | 成功 | - |
| 1 | 認証エラー (401/403) | API トークンを再確認 |
| 2 | リソースなし (404) | チケットキーを確認 |
| 3 | レート制限 (429) | 自動リトライ後も失敗。時間を置く |
| 4 | その他エラー | エラーメッセージを確認 |

レート制限（429）はスクリプトが自動で最大3回リトライする。

### セキュリティ

- 認証情報はリポジトリ外（`~/.config/jira/credentials`）に保管
- `.gitignore` で `credentials`, `*.token`, `.env` を除外済み
- `credentials` のパーミッションは `600`（所有者のみ読み書き）
- スクリプトの出力にトークンやパスワードは含まれない

### 依存

| ツール | 確認 | 備考 |
|--------|------|------|
| `curl` | `which curl` | macOS 標準 |
| `jq` | `which jq` | なければ `brew install jq` |
| `base64` | `which base64` | macOS 標準 |
| `python3` | `which python3` | URL エンコード用。macOS 標準 |

### カスタム認証情報ファイル

デフォルト以外の場所に credentials を置きたい場合:

```bash
JIRA_CRED_FILE=/path/to/credentials ./scripts/jira.sh myself
```

環境変数 `JIRA_CRED_FILE` で上書きできる。
